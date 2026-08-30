import AppTrackingTransparency
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var pendingTrackingResults: [FlutterResult] = []
  private var isRequestingTrackingAuthorization = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let trackingChannel = FlutterMethodChannel(
      name: "tvremote/app_tracking_transparency",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    trackingChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "requestTrackingAuthorization" else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.requestTrackingAuthorization(result: result)
    }
  }

  private func requestTrackingAuthorization(result: @escaping FlutterResult) {
    guard #available(iOS 14, *) else {
      result("notSupported")
      return
    }

    let status = ATTrackingManager.trackingAuthorizationStatus
    guard status == .notDetermined else {
      result(trackingStatusName(status))
      return
    }

    pendingTrackingResults.append(result)
    requestTrackingAuthorizationWhenActive()
  }

  @available(iOS 14, *)
  private func requestTrackingAuthorizationWhenActive() {
    guard !isRequestingTrackingAuthorization else { return }

    guard UIApplication.shared.applicationState == .active else {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(applicationBecameActiveForTracking),
        name: UIApplication.didBecomeActiveNotification,
        object: nil
      )
      return
    }

    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    isRequestingTrackingAuthorization = true

    ATTrackingManager.requestTrackingAuthorization { [weak self] status in
      DispatchQueue.main.async {
        guard let self else { return }
        let statusName = self.trackingStatusName(status)
        let results = self.pendingTrackingResults
        self.pendingTrackingResults.removeAll()
        self.isRequestingTrackingAuthorization = false
        results.forEach { $0(statusName) }
      }
    }
  }

  @objc private func applicationBecameActiveForTracking() {
    if #available(iOS 14, *) {
      requestTrackingAuthorizationWhenActive()
    }
  }

  @available(iOS 14, *)
  private func trackingStatusName(_ status: ATTrackingManager.AuthorizationStatus) -> String {
    switch status {
    case .authorized:
      return "authorized"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    case .notDetermined:
      return "notDetermined"
    @unknown default:
      return "unavailable"
    }
  }
}
