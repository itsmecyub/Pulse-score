import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Matches ReviewChannelLauncher in lib/features/review/review_prompter.dart.
  private static let reviewChannelName = "pulsescore/review"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // The bridge does not vend a messenger directly; it comes from the
    // application registrar, which is where engine-wide services live.
    registerReviewChannel(with: engineBridge.applicationRegistrar.messenger())
  }

  /// Asks StoreKit for the rating dialog.
  ///
  /// This exists instead of leaning on `in_app_review` because that plugin
  /// resolves the scene with `UIApplication.shared.connectedScenes.first`.
  /// `connectedScenes` is a Set, so `first` is whichever element the hash
  /// order happens to yield — frequently a background or unattached scene, and
  /// StoreKit silently does nothing when handed one. Picking the
  /// foreground-active scene explicitly is what makes the dialog appear.
  private func registerReviewChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: AppDelegate.reviewChannelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "requestReview" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let scene = AppDelegate.activeWindowScene() else {
        result(false)
        return
      }

      if #available(iOS 16.0, *) {
        // AppStore.requestReview must run on the main actor.
        DispatchQueue.main.async {
          AppStore.requestReview(in: scene)
        }
      } else {
        SKStoreReviewController.requestReview(in: scene)
      }
      result(true)
    }
  }

  private static func activeWindowScene() -> UIWindowScene? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.first { $0.activationState == .foregroundActive }
      // A scene that is merely foreground-inactive still works; only a
      // background one is useless. Fall back rather than give up.
      ?? scenes.first { $0.activationState == .foregroundInactive }
      ?? scenes.first
  }
}
