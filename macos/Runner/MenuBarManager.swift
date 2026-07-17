import Cocoa
import FlutterMacOS

/// 管理 macOS 菜单栏（状态栏）歌词显示。
///
/// 功能：
/// - 在菜单栏显示当前播放歌曲信息或歌词
/// - 歌词过长时自动滚动显示
/// - 歌词为空时显示歌曲标题和艺术家
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var scrollTimer: Timer?
    private var currentText: String = ""
    private var scrollOffset: Int = 0
    private var channel: FlutterMethodChannel?

    /// 初始化并创建状态栏项。
    func setup(channel: FlutterMethodChannel) {
        self.channel = channel
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "乐岛"
            button.font = NSFont.menuBarFont(ofSize: 0)
        }

        // 设置点击回调
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(statusItemClicked)
    }

    /// 清理资源。
    func teardown() {
        stopScrolling()
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        channel = nil
    }

    /// 更新显示的文本。
    /// - Parameters:
    ///   - text: 要显示的文本
    ///   - scrollable: 是否支持滚动
    func updateText(_ text: String, scrollable: Bool = false) {
        guard statusItem != nil else { return }

        // 停止之前的滚动
        stopScrolling()

        currentText = text

        // 状态栏宽度限制（约 50 字符）
        let maxLength = 50
        if text.count > maxLength && scrollable {
            // 启动滚动
            startScrolling()
        } else {
            // 直接显示
            displayText(text)
        }
    }

    /// 更新曲目信息。
    func updateTrackInfo(title: String, artist: String?) {
        let text: String
        if let artist = artist, !artist.isEmpty {
            text = "\(title) - \(artist)"
        } else {
            text = title
        }
        updateText(text, scrollable: true)
    }

    /// 更新歌词行。
    func updateLyric(_ text: String) {
        updateText(text, scrollable: false)
    }

    /// 清空显示（无播放时）。
    func clear() {
        stopScrolling()
        currentText = ""
        scrollOffset = 0
        displayText("乐岛")
    }

    // MARK: - Private

    private func displayText(_ text: String) {
        if let button = statusItem?.button {
            button.title = text.isEmpty ? "乐岛" : text
        }
    }

    private func startScrolling() {
        guard !currentText.isEmpty else { return }

        // 显示初始文本
        let visibleText = String(currentText.prefix(30))
        self.displayText(visibleText)

        // 每 200ms 更新一次
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.scrollTick()
        }
    }

    private func scrollTick() {
        guard !currentText.isEmpty else {
            stopScrolling()
            return
        }

        let maxLength = 30
        let textLength = currentText.count

        if textLength <= maxLength {
            displayText(currentText)
            stopScrolling()
            return
        }

        // 循环滚动
        let fullText = currentText + "   " + currentText
        let startIndex = currentText.index(currentText.startIndex, offsetBy: scrollOffset % textLength)
        let endIndex = fullText.index(startIndex, offsetBy: maxLength)
        let visibleText = String(fullText[startIndex..<endIndex])

        displayText(visibleText)

        scrollOffset += 1
    }

    private func stopScrolling() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        scrollOffset = 0
    }

    @objc private func statusItemClicked() {
        // 通知 Flutter 层点击事件
        channel?.invokeMethod("onMenuBarClicked", arguments: nil)
    }
}
