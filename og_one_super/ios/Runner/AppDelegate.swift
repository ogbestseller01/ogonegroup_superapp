import Flutter
import UIKit
import Darwin

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

    // ── Security MethodChannel ────────────────────────────────
    let channel = FlutterMethodChannel(
      name: "og.one.security",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "isDeveloperMode":
        result(self?.isDebuggerAttached() ?? false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    // ─────────────────────────────────────────────────────────
  }

  /// Detects if a debugger is attached (closest iOS equivalent of debug mode)
  private func isDebuggerAttached() -> Bool {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

    let sysctlResult = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
    if sysctlResult != 0 {
      return false
    }

    return (info.kp_proc.p_flag & P_TRACED) != 0
  }
}