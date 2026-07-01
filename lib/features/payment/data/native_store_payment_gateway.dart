import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/payment_gateway.dart';
import '../domain/payment_intent.dart';

class NativeStorePaymentGateway implements PaymentGateway {
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
    if (productId.isEmpty) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: 'This movie is not ready for in-app purchase yet.',
      );
    }

    final bool isAvailable;
    try {
      isAvailable = await _inAppPurchase.isAvailable();
    } on PlatformException catch (error) {
      _logNativeStoreError(storeLabel, 'isAvailable', error, productId);
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: _nativeStorePlatformMessage(storeLabel, error),
      );
    }

    if (!isAvailable) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: 'In-app purchases are not available on this device.',
      );
    }

    final ProductDetailsResponse productResponse;
    try {
      productResponse = await _inAppPurchase.queryProductDetails({productId});
    } on PlatformException catch (error) {
      _logNativeStoreError(storeLabel, 'queryProductDetails', error, productId);
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: _nativeStorePlatformMessage(storeLabel, error),
      );
    }

    final productError = productResponse.error;
    if (productError != null) {
      debugPrint(
        '[$storeLabel] queryProductDetails error '
        'productId=$productId code=${productError.code} '
        'message=${productError.message} details=${productError.details}',
      );
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
      debugPrint(
        '[$storeLabel] product not found productId=$productId '
        'notFoundIDs=${productResponse.notFoundIDs}',
      );
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: 'This movie purchase is not available in the store yet.',
      );
    }

    final completer = Completer<GatewayPaymentResult>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;

    subscription = _inAppPurchase.purchaseStream.listen(
      (purchases) {
        _handlePurchaseUpdates(
          purchases: purchases,
          productId: productId,
          txRef: intent.txRef,
          storeLabel: storeLabel,
          completer: completer,
        );
      },
      onError: (Object error) {
        debugPrint('[$storeLabel] purchase stream error: $error');
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
      purchaseStarted = await _inAppPurchase.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: productDetails),
        autoConsume: intent.method != PaymentMethod.googlePlay,
      );
    } on PlatformException catch (error) {
      await subscription.cancel();
      _logNativeStoreError(storeLabel, 'buyConsumable', error, productId);
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: _nativeStorePlatformMessage(storeLabel, error),
      );
    }

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
        return GatewayPaymentResult(
          status: GatewayPaymentStatus.failed,
          txRef: intent.txRef,
          message: 'The store is taking too long to respond. Please try again.',
        );
      },
    );

    await subscription.cancel();
    return result;
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
    if (purchase == null || !purchase.pendingCompletePurchase) return;

    await _inAppPurchase.completePurchase(purchase);
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
      final isProductlessTerminalUpdate =
          purchase.productID.isEmpty &&
          (purchase.status == PurchaseStatus.canceled ||
              purchase.status == PurchaseStatus.error);

      if (purchase.productID != productId && !isProductlessTerminalUpdate) {
        continue;
      }

      debugPrint(
        '[$storeLabel] purchase update productId=${purchase.productID} '
        'expectedProductId=$productId '
        'status=${purchase.status.name} purchaseId=${purchase.purchaseID} '
        'errorCode=${purchase.error?.code} '
        'errorMessage=${purchase.error?.message} '
        'errorDetails=${purchase.error?.details}',
      );

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final completionKey = _completionKeyFor(purchase);
          _pendingCompletions[completionKey] = purchase;
          completer.complete(
            GatewayPaymentResult(
              status: GatewayPaymentStatus.completed,
              txRef: txRef,
              transactionId: purchase.purchaseID ?? completionKey,
              nativeVerificationData: NativePurchaseVerificationData(
                completionKey: completionKey,
                productId: purchase.productID,
                purchaseId: purchase.purchaseID,
                transactionDate: purchase.transactionDate,
                source: purchase.verificationData.source,
                localVerificationData:
                    purchase.verificationData.localVerificationData,
                serverVerificationData:
                    purchase.verificationData.serverVerificationData,
              ),
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

  String _storeLabelFor(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.storeKit => 'StoreKit',
      PaymentMethod.googlePlay => 'Google Play Billing',
      _ => 'Native Store',
    };
  }

  void _logNativeStoreError(
    String storeLabel,
    String action,
    PlatformException error,
    String productId,
  ) {
    debugPrint(
      '[$storeLabel] $action failed productId=$productId '
      'code=${error.code} message=${error.message} details=${error.details}',
    );
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
