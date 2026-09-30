import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let refundChannel = FlutterMethodChannel(
      name: "com.africanmovies.mobile/storekit_refund",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    refundChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "beginRefundRequest" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self else {
        result(
          FlutterError(
            code: "storekit_unavailable",
            message: "App Store refund requests are temporarily unavailable.",
            details: nil
          )
        )
        return
      }

      self.beginStoreKitRefundRequest(call: call, result: result)
    }
  }

  private func beginStoreKitRefundRequest(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let rawTransactionID = arguments["transactionId"] as? String,
      let transactionID = UInt64(rawTransactionID)
    else {
      result(
        FlutterError(
          code: "invalid_transaction",
          message: "A valid Apple transaction ID is required.",
          details: nil
        )
      )
      return
    }

    Task { @MainActor in
      guard let windowScene = activeWindowScene() else {
        result(
          FlutterError(
            code: "no_window_scene",
            message: "Open AfricanMovies and try the refund request again.",
            details: nil
          )
        )
        return
      }

      do {
        let status = try await StoreKit.Transaction.beginRefundRequest(
          for: transactionID,
          in: windowScene
        )
        switch status {
        case .success:
          result("submitted")
        case .userCancelled:
          result("cancelled")
        @unknown default:
          result(
            FlutterError(
              code: "unknown_status",
              message: "The App Store returned an unknown refund status.",
              details: nil
            )
          )
        }
      } catch StoreKit.Transaction.RefundRequestError.duplicateRequest {
        result(
          FlutterError(
            code: "duplicate_request",
            message: "A refund request already exists for this purchase.",
            details: nil
          )
        )
      } catch StoreKit.Transaction.RefundRequestError.failed {
        result(
          FlutterError(
            code: "request_failed",
            message: "The App Store could not start the refund request.",
            details: nil
          )
        )
      } catch {
        result(
          FlutterError(
            code: "storekit_error",
            message: "The App Store could not start the refund request.",
            details: String(describing: error)
          )
        )
      }
    }
  }

  @MainActor
  private func activeWindowScene() -> UIWindowScene? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
  }
}
