import '../data/apple_refund_request_gateway.dart';
import '../domain/apple_refund_consent.dart';

typedef AppleRefundConsentLoader =
    Future<AppleRefundConsent> Function(String transactionId);
typedef AppleRefundConsentUpdater =
    Future<AppleRefundConsent> Function({
      required String transactionId,
      required bool consented,
    });
typedef AppleRefundRequestStarter =
    Future<AppleRefundRequestStatus> Function(String transactionId);

class AppleRefundRequestCoordinator {
  final AppleRefundConsentLoader _loadConsent;
  final AppleRefundConsentUpdater _updateConsent;
  final AppleRefundRequestStarter _beginRefundRequest;

  const AppleRefundRequestCoordinator({
    required AppleRefundConsentLoader loadConsent,
    required AppleRefundConsentUpdater updateConsent,
    required AppleRefundRequestStarter beginRefundRequest,
  }) : _loadConsent = loadConsent,
       _updateConsent = updateConsent,
       _beginRefundRequest = beginRefundRequest;

  Future<bool> loadCurrentConsent(String transactionId) async {
    final consent = await _loadConsent(transactionId);
    return consent.hasCurrentConsent;
  }

  Future<AppleRefundRequestStatus> requestRefund({
    required String transactionId,
    required bool shareViewingActivity,
  }) async {
    await _updateConsent(
      transactionId: transactionId,
      consented: shareViewingActivity,
    );

    return _beginRefundRequest(transactionId);
  }
}
