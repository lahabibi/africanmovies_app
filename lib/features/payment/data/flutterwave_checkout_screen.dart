import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/payment_gateway.dart';

class FlutterwaveCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;
  final String fallbackTxRef;

  const FlutterwaveCheckoutScreen({
    super.key,
    required this.checkoutUrl,
    required this.fallbackTxRef,
  });

  @override
  State<FlutterwaveCheckoutScreen> createState() =>
      _FlutterwaveCheckoutScreenState();
}

class _FlutterwaveCheckoutScreenState extends State<FlutterwaveCheckoutScreen> {
  double _progress = 0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _closeAsCancelled();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _CheckoutHeader(onClose: _closeAsCancelled),
              if (_progress < 1)
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  minHeight: 2,
                  color: AppColors.heroButton,
                  backgroundColor: AppColors.cardBorder,
                )
              else
                SizedBox(height: 2.h),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(widget.checkoutUrl),
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: false,
                    allowsBackForwardNavigationGestures: false,
                  ),
                  onLoadStart: (_, url) => _processUrl(url),
                  onLoadStop: (_, url) => _processUrl(url),
                  onProgressChanged: (_, progress) {
                    if (!mounted) return;
                    setState(() => _progress = progress / 100);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processUrl(WebUri? webUri) {
    if (_completed || webUri == null) return;

    final result = _resultFromUri(webUri);
    if (result == null) return;

    _completed = true;
    Navigator.pop(context, result);
  }

  GatewayPaymentResult? _resultFromUri(Uri uri) {
    final response = uri.queryParameters['response'];
    if (response != null && response.isNotEmpty) {
      return _resultFromAppendedResponse(response);
    }

    final status = uri.queryParameters['status'];
    final txRef = uri.queryParameters['tx_ref'];
    if (status == null || txRef == null) return null;

    return _resultFromValues(
      status: status,
      txRef: txRef,
      transactionId: uri.queryParameters['transaction_id'],
    );
  }

  GatewayPaymentResult? _resultFromAppendedResponse(String response) {
    try {
      final decodedText = Uri.decodeFull(response);
      final decoded = jsonDecode(decodedText);
      if (decoded is! Map) return null;

      return _resultFromValues(
        status: decoded['status']?.toString(),
        txRef: decoded['txRef']?.toString(),
        transactionId: decoded['id']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  GatewayPaymentResult? _resultFromValues({
    required String? status,
    required String? txRef,
    required String? transactionId,
  }) {
    final normalizedStatus = status?.trim().toLowerCase();
    final normalizedTxRef = txRef?.trim().isNotEmpty == true
        ? txRef!.trim()
        : widget.fallbackTxRef;

    if (normalizedStatus == null || normalizedStatus.isEmpty) return null;

    if (_isSuccessfulStatus(normalizedStatus)) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.completed,
        txRef: normalizedTxRef,
        transactionId: transactionId?.trim(),
      );
    }

    if (normalizedStatus == 'cancelled') {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.cancelled,
        txRef: normalizedTxRef,
      );
    }

    return GatewayPaymentResult(
      status: GatewayPaymentStatus.failed,
      txRef: normalizedTxRef,
      transactionId: transactionId?.trim(),
      message: 'Payment could not be completed.',
    );
  }

  bool _isSuccessfulStatus(String status) {
    return status == 'success' ||
        status == 'successful' ||
        status == 'completed';
  }

  void _closeAsCancelled() {
    if (_completed) return;

    _completed = true;
    Navigator.pop(
      context,
      GatewayPaymentResult(
        status: GatewayPaymentStatus.cancelled,
        txRef: widget.fallbackTxRef,
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _CheckoutHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: Colors.white, size: 23.sp),
          ),
          Expanded(
            child: Text(
              'Secure Checkout',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }
}
