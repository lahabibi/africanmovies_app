import 'dart:async';

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
    final productId = intent.storeProductId?.trim() ?? '';
    if (productId.isEmpty) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: 'This movie is not ready for in-app purchase yet.',
      );
    }

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: 'In-app purchases are not available on this device.',
      );
    }

    final productResponse = await _inAppPurchase.queryProductDetails({
      productId,
    });
    final productError = productResponse.error;
    if (productError != null) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: intent.txRef,
        message: productError.message,
      );
    }

    final productDetails = _findProductDetails(
      productResponse.productDetails,
      productId,
    );
    if (productDetails == null ||
        productResponse.notFoundIDs.contains(productId)) {
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
          completer: completer,
        );
      },
      onError: (Object error) {
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

    final purchaseStarted = await _inAppPurchase.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: productDetails),
      autoConsume: intent.method != PaymentMethod.googlePlay,
    );
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
    required Completer<GatewayPaymentResult> completer,
  }) {
    if (completer.isCompleted) return;

    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;

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
              message:
                  purchase.error?.message ??
                  'In-app purchase could not be completed.',
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
}
