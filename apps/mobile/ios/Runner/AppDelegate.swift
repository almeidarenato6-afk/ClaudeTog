import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not a FlutterViewController")
    }

    BluetoothTransportPlugin(messenger: controller.binaryMessenger).register()
    WatchCompanionPlugin(messenger: controller.binaryMessenger).register()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
