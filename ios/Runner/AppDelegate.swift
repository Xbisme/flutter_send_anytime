import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // #011 (T032): a UIApplication background-task assertion that buys the
  // in-flight WebRTC transfer ~30s of extra background runtime when the app is
  // minimized, so a brief background stint doesn't drop the transfer instantly.
  private var bgTaskId: UIBackgroundTaskIdentifier = .invalid

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SafeSendBgTask") {
      let channel = FlutterMethodChannel(
        name: "app.safesend/bgtask",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "begin":
          self?.beginBgTask()
          result(nil)
        case "end":
          self?.endBgTask()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  private func beginBgTask() {
    endBgTask()
    bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "SafeSendTransfer") {
      [weak self] in
      self?.endBgTask()
    }
  }

  private func endBgTask() {
    if bgTaskId != .invalid {
      UIApplication.shared.endBackgroundTask(bgTaskId)
      bgTaskId = .invalid
    }
  }
}
