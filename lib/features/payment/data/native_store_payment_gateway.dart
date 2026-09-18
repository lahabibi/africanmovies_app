import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/payment_gateway.dart';
import '../domain/payment_intent.dart';

const bool _nativeStoreDiagnosticsEnabled = bool.fromEnvironment(
  'AM_NATIVE_STORE_DIAGNOSTICS',
  defaultValue: false,
);

class NativeStorePaymentGateway implements PaymentGateway {
  static const _duplicatePurchaseStreamWait = Duration(seconds: 8);

  NativeStorePaymentGateway({
    InAppPurchase? inAppPurchase,
    Duration purchaseTimeout = const Duration(minutes: 3),
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
       _purchaseTimeout = purchaseTimeout;

  final InAppPurchase _inAppPurchase;
  final Duration _purchaseTimeout;
  final Map<String, PurchaseDetails> _pendingCompletions = {};

  @override
  Future<GatewayPaymentResult> charge({
    required BuildContext context,
    required PaymentIntent intent,
  }) async {
    final storeLabel = _storeLabelFor(intent.method);
    final productId = intent.storeProductId?.trim() ?? '';
    _log(
      'charge started store=$storeLabel productId=$productId '
      'txRef=${_tail(intent.txRef)} account=${_tail(intent.storeAccountId)}',
    );
    if (productId.isEmpty) {
      _log('charge failed before store call: empty productId');
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: 'This movie is not ready for in-app purchase yet.',
      );
    }

    final bool isAvailable;
    try {
      _log('checking store availability');
      isAvailable = await _inAppPurchase.isAvailable();
    } on PlatformException catch (error) {
      _logPlatformException('isAvailable failed', error);
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: _nativeStorePlatformMessage(storeLabel, error),
      );
    }

    _log('store availability result=$isAvailable');
    if (!isAvailable) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: 'In-app purchases are not available on this device.',
      );
    }

    final ProductDetailsResponse productResponse;
    try {
      _log('querying product details for $productId');
      productResponse = await _inAppPurchase.queryProductDetails({productId});
    } on PlatformException catch (error) {
      _logPlatformException('queryProductDetails platform exception', error);
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: _nativeStorePlatformMessage(storeLabel, error),
      );
    }

    _log(
      'queryProductDetails result products='
      '${productResponse.productDetails.map((product) => product.id).join(',')} '
      'notFound=${productResponse.notFoundIDs.join(',')} '
      'error=${_iapErrorSummary(productResponse.error)}',
    );
    final productError = productResponse.error;
    if (productError != null) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: _friendlyStoreFailureMessage(
          storeLabel: storeLabel,
          code: productError.code,
          message: productError.message,
          details: productError.details,
        ),
      );
    }

    final productDetails = _findProductDetails(
      productResponse.productDetails,
      productId,
    );
    if (productDetails == null ||
        productResponse.notFoundIDs.contains(productId)) {
      _log('product not available after query productId=$productId');
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: 'This movie purchase is not available in the store yet.',
      );
    }

    final completer = Completer<GatewayPaymentResult>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;

    _log('listening for purchase updates');
    subscription = _inAppPurchase.purchaseStream.listen(
      (purchases) {
        _log('purchaseStream update count=${purchases.length}');
        _handlePurchaseUpdates(
          purchases: purchases,
          productId: productId,
          txRef: intent.txRef,
          storeLabel: storeLabel,
          completer: completer,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        _log('purchaseStream error ${error.runtimeType}: $error');
        if (completer.isCompleted) return;
        completer.complete(
          GatewayPaymentResult(
            status: GatewayPaymentStatus.failed,
            txRef: intent.txRef,
            message: 'Unable to complete in-app purchase. Please try again.',
          ),
        );
      },
    );

    final bool purchaseStarted;
    try {
      _log(
        'starting buyConsumable autoConsume=${intent.method != PaymentMethod.googlePlay}',
      );
      purchaseStarted = await _inAppPurchase.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: productDetails,
          applicationUserName: intent.storeAccountId,
        ),
        autoConsume: intent.method != PaymentMethod.googlePlay,
      );
    } on PlatformException catch (error) {
      _logPlatformException('buyConsumable failed', error);
      if (_isDuplicatePendingProductError(error)) {
        final streamedResult = await _streamedResultAfterDuplicate(completer);
        if (streamedResult != null) {
          await subscription.cancel();
          _log(
            'buyConsumable duplicate resolved from purchase stream '
            'status=${streamedResult.status.name}',
          );
          return streamedResult;
        }

        await subscription.cancel();
        _log(
          'buyConsumable duplicate had no stream result after '
          '${_duplicatePurchaseStreamWait.inSeconds}s; keeping attempt pending',
        );
        return GatewayPaymentResult(
          status: GatewayPaymentStatus.pending,
          txRef: intent.txRef,
          message:
              'Your purchase is awaiting App Store confirmation. We will update your library automatically.',
        );
      }

      await subscription.cancel();
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: _nativeStorePlatformMessage(storeLabel, error),
      );
    }

    _log('buyConsumable returned purchaseStarted=$purchaseStarted');
    if (!purchaseStarted) {
      await subscription.cancel();
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: 'Unable to start in-app purchase. Please try again.',
      );
    }

    final result = await completer.future.timeout(
      _purchaseTimeout,
      onTimeout: () {
        _log('purchase timed out after ${_purchaseTimeout.inSeconds}s');
        return GatewayPaymentResult(
          status: GatewayPaymentStatus.pending,
          txRef: intent.txRef,
          message:
              'Your payment is awaiting confirmation. We will update your library automatically.',
        );
      },
    );

    await subscription.cancel();
    _log(
      'charge finished status=${result.status.name} txRef=${_tail(result.txRef)}',
    );
    return result;
  }

  Future<GatewayPaymentResult?> _streamedResultAfterDuplicate(
    Completer<GatewayPaymentResult> completer,
  ) {
    if (completer.isCompleted) return completer.future;

    return completer.future
        .then<GatewayPaymentResult?>((result) => result)
        .timeout(_duplicatePurchaseStreamWait, onTimeout: () => null);
  }

  @override
  Future<GatewayPaymentResult> authorizeRedirect({
    required BuildContext context,
    required String redirectUrl,
    required String fallbackTxRef,
  }) async {
    return GatewayPaymentResult(
      status: GatewayPaymentStatus.failed,
      txRef: fallbackTxRef,
      message: 'In-app purchases do not use card authorization redirects.',
    );
  }

  Future<void> completePurchase(String completionKey) async {
    final purchase = _pendingCompletions.remove(completionKey);
    if (purchase == null) {
      _log('completePurchase skipped: no pending purchase for $completionKey');
      return;
    }

    if (!purchase.pendingCompletePurchase) {
      _log('completePurchase skipped: store says completion is not pending');
      return;
    }

    _log('completePurchase started ${_purchaseSummary(purchase)}');
    await _inAppPurchase.completePurchase(purchase);
    _log('completePurchase finished completionKey=$completionKey');
  }

  ProductDetails? _findProductDetails(
    List<ProductDetails> products,
    String productId,
  ) {
    for (final product in products) {
      if (product.id == productId) return product;
    }

    return null;
  }

  void _handlePurchaseUpdates({
    required List<PurchaseDetails> purchases,
    required String productId,
    required String txRef,
    required String storeLabel,
    required Completer<GatewayPaymentResult> completer,
  }) {
    if (completer.isCompleted) return;

    for (final purchase in purchases) {
      _log('purchase update ${_purchaseSummary(purchase)}');
      final isProductlessTerminalUpdate =
          purchase.productID.isEmpty &&
          (purchase.status == PurchaseStatus.canceled ||
              purchase.status == PurchaseStatus.error);

      if (purchase.productID != productId && !isProductlessTerminalUpdate) {
        _log(
          'ignoring purchase update for product=${purchase.productID}; '
          'waiting for product=$productId',
        );
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          completer.complete(
            GatewayPaymentResult(
              status: GatewayPaymentStatus.pending,
              txRef: txRef,
              transactionId: purchase.purchaseID,
              nativeVerificationData: _verificationDataFor(purchase),
            ),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final completionKey = _completionKeyFor(purchase);
          _pendingCompletions[completionKey] = purchase;
          completer.complete(
            GatewayPaymentResult(
              status: GatewayPaymentStatus.completed,
              txRef: txRef,
              transactionId: purchase.purchaseID ?? completionKey,
              nativeVerificationData: _verificationDataFor(purchase),
            ),
          );
        case PurchaseStatus.canceled:
          completer.complete(
            GatewayPaymentResult(
              status: GatewayPaymentStatus.cancelled,
              txRef: txRef,
            ),
          );
        case PurchaseStatus.error:
          completer.complete(
            GatewayPaymentResult(
              status: GatewayPaymentStatus.failed,
              txRef: txRef,
              message: _friendlyStoreFailureMessage(
                storeLabel: storeLabel,
                code: purchase.error?.code,
                message: purchase.error?.message,
                details: purchase.error?.details,
                duringCheckout: true,
              ),
            ),
          );
      }
    }
  }

  String _completionKeyFor(PurchaseDetails purchase) {
    final purchaseId = purchase.purchaseID?.trim();
    if (purchaseId != null && purchaseId.isNotEmpty) return purchaseId;

    return [
      purchase.productID,
      purchase.transactionDate,
      purchase.verificationData.source,
      purchase.verificationData.serverVerificationData.hashCode,
    ].join(':');
  }

  NativePurchaseVerificationData _verificationDataFor(
    PurchaseDetails purchase,
  ) {
    return NativePurchaseVerificationData(
      completionKey: _completionKeyFor(purchase),
      productId: purchase.productID,
      purchaseId: purchase.purchaseID,
      transactionDate: purchase.transactionDate,
      source: purchase.verificationData.source,
      localVerificationData: purchase.verificationData.localVerificationData,
      serverVerificationData: purchase.verificationData.serverVerificationData,
    );
  }

  String _storeLabelFor(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.storeKit => 'StoreKit',
      PaymentMethod.googlePlay => 'Google Play Billing',
      _ => 'Native Store',
    };
  }

  String _nativeStorePlatformMessage(
    String storeLabel,
    PlatformException error,
  ) {
    return _friendlyStoreFailureMessage(
      storeLabel: storeLabel,
      code: error.code,
      message: error.message,
      details: error.details,
    );
  }

  void _log(String message) {
    if (!_nativeStoreDiagnosticsEnabled) return;
    debugPrint('[NativeStorePayment] $message');
  }

  void _logPlatformException(String label, PlatformException error) {
    _log(
      '$label code=${error.code} message=${error.message} '
      'details=${error.details}',
    );
  }

  String _iapErrorSummary(IAPError? error) {
    if (error == null) return 'none';

    return 'code=${error.code} message=${error.message} '
        'details=${error.details}';
  }

  String _purchaseSummary(PurchaseDetails purchase) {
    final verificationData = purchase.verificationData;
    return 'product=${purchase.productID} status=${purchase.status.name} '
        'pendingComplete=${purchase.pendingCompletePurchase} '
        'purchaseId=${_tail(purchase.purchaseID)} '
        'transactionDate=${purchase.transactionDate} '
        'source=${verificationData.source} '
        'serverDataLength=${verificationData.serverVerificationData.length} '
        'error=${_iapErrorSummary(purchase.error)}';
  }

  String _tail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'empty';
    if (text.length <= 8) return text;
    return '...${text.substring(text.length - 8)}';
  }

  bool _isDuplicatePendingProductError(PlatformException error) {
    final diagnostic = [
      error.code,
      error.message,
      error.details?.toString(),
    ].whereType<String>().join(' ').toLowerCase();

    return diagnostic.contains('duplicate') ||
        diagnostic.contains('pending transaction') ||
        diagnostic.contains('storekit_duplicate_product_object');
  }

  String _friendlyStoreFailureMessage({
    required String storeLabel,
    String? code,
    String? message,
    Object? details,
    bool duringCheckout = false,
  }) {
    final diagnostic = [
      code,
      message,
      details?.toString(),
    ].whereType<String>().join(' ').toLowerCase();

    if (diagnostic.contains('declin') || diagnostic.contains('denied')) {
      return 'Your payment was declined. Please choose another payment method and try again.';
    }

    if (diagnostic.contains('network')) {
      return 'We could not reach the store. Check your connection and try again.';
    }

    if (diagnostic.contains('itemalreadyowned') ||
        diagnostic.contains('item already owned')) {
      return 'This purchase is already being processed. Please refresh your library and try again.';
    }

    if (diagnostic.contains('duplicate') ||
        diagnostic.contains('pending transaction') ||
        diagnostic.contains('storekit_duplicate_product_object')) {
      return 'This purchase is still being finalized by the App Store. Please wait a moment and try again.';
    }

    if (duringCheckout &&
        (diagnostic.contains('billingunavailable') ||
            diagnostic.contains('billing_unavailable'))) {
      return 'We could not complete this payment. Please choose another payment method or try again.';
    }

    if (diagnostic.contains('billingunavailable') ||
        diagnostic.contains('billing_unavailable') ||
        diagnostic.contains('serviceunavailable') ||
        diagnostic.contains('storekit_no_response')) {
      return '$storeLabel is temporarily unavailable. Please try again shortly.';
    }

    return 'Payment could not be completed. Please try again or choose another payment method.';
  }
}
