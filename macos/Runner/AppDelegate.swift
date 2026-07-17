import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var menuBarManager: MenuBarManager?

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in NSApp.windows {
                if window.contentViewController is FlutterViewController {
                    window.orderFront(nil)
                    break
                }
            }
        }
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
            return
        }

        let channel = FlutterMethodChannel(
            name: "com.melisle/menu_bar",
            binaryMessenger: controller.engine.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "init":
                self?.menuBarManager = MenuBarManager()
                self?.menuBarManager?.setup(channel: channel)
                result(nil)

            case "updateText":
                guard let args = call.arguments as? [String: Any],
                      let text = args["text"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing text argument", details: nil))
                    return
                }
                let scrollable = args["scrollable"] as? Bool ?? false
                self?.menuBarManager?.updateText(text, scrollable: scrollable)
                result(nil)

            case "updateTrackInfo":
                guard let args = call.arguments as? [String: Any],
                      let title = args["title"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing title argument", details: nil))
                    return
                }
                let artist = args["artist"] as? String
                self?.menuBarManager?.updateTrackInfo(title: title, artist: artist)
                result(nil)

            case "updateLyric":
                guard let args = call.arguments as? [String: Any],
                      let text = args["text"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing text argument", details: nil))
                    return
                }
                self?.menuBarManager?.updateLyric(text)
                result(nil)

            case "clear":
                self?.menuBarManager?.clear()
                result(nil)

            case "dispose":
                self?.menuBarManager?.teardown()
                self?.menuBarManager = nil
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
