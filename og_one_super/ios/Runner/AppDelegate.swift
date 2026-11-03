import Flutter
import UIKit
// `import Darwin` is not required — Foundation re-exports it.

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
      case "isJailbroken":
        result(self?.isJailbroken() ?? false)   // ← added, see below
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    // ─────────────────────────────────────────────────────────
  }

  /// Detects if a debugger is attached.
  private func isDebuggerAttached() -> Bool {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return false }
    return (info.kp_proc.p_flag & P_TRACED) != 0
  }

  /// Basic jailbreak heuristic — extend as needed.
  private func isJailbroken() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    let suspiciousPaths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt/",
      "/private/var/lib/cydia",
      "/private/var/stash"
    ]
    for path in suspiciousPaths where FileManager.default.fileExists(atPath: path) {
      return true
    }
    // Sandbox escape test
    let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
    do {
      try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
      try FileManager.default.removeItem(atPath: testPath)
      return true
    } catch {
      return false
    }
    #endif
  }
}