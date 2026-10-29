import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let carHudChannel = FlutterMethodChannel(
      name: "com.dlinii.app/car_hud",
      binaryMessenger: controller.binaryMessenger
    )
    carHudChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "updateHud":
        DliniiCarPlayStore.shared.update(call.arguments as? [String: Any])
        result(nil)
      case "clearHud":
        DliniiCarPlayStore.shared.clear()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}