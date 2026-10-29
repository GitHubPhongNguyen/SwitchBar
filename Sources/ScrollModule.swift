import AppKit
import Carbon.HIToolbox

/// Flips Natural scrolling with one click on the icon, or with a shortcut that works even while the icon is hidden.
final class ScrollModule: MenuBarModule {
    static let hotKeyKey = "scroll.hotKey"
    let hotKey = HotKey(keyCode: kVK_ANSI_S, modifiers: controlKey | optionKey | cmdKey, display: "⌃⌥⌘S")

    init() {
        super.init(id: "scroll", title: "Hướng cuộn", summary: "Đổi nhanh giữa cuộn tự nhiên và kiểu chuột", symbolName: "hand.draw")
        hotKey.onPress = { [weak self] in self?.toggle() }
        // Refreshes the icon whenever the setting changes, including edits made in System Settings.
        DistributedNotificationCenter.default().addObserver(
            forName: ScrollDirection.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.refreshIcon()
        }
    }

    func setHotKeyEnabled(_ enabled: Bool) {
        guard enabled else {
            hotKey.unregister()
            return
        }
        if !hotKey.register() {
            UserDefaults.standard.set(false, forKey: Self.hotKeyKey)
            showAlert("Không bật được phím tắt \(hotKey.display)", "Có thể một app khác đang dùng tổ hợp phím này.")
        }
    }

    override func didShow(_ item: NSStatusItem) {
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        refreshIcon()
    }

    // MARK: - Status bar icon

    private func refreshIcon() {
        guard let button = statusItem?.button else { return }
        let direction = ScrollDirection.current
        let image = NSImage(systemSymbolName: direction.symbolName, accessibilityDescription: "Cuộn \(direction.title)")
        image?.isTemplate = true
        button.image = image
        button.toolTip = "Đang cuộn: \(direction.title)\nBấm để đổi · bấm chuột phải để mở menu"
    }

    /// Left click switches right away; right click or Control-click opens the menu.
    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
        } else {
            toggle()
        }
    }

    // MARK: - Menu

    override func buildMenu(_ menu: NSMenu) {
        let current = ScrollDirection.current
        menu.addItem(.sectionHeader(title: "Hướng cuộn"))
        for direction in [ScrollDirection.natural, .traditional] {
            let item = actionItem(direction.title, #selector(chooseDirection(_:)))
            item.representedObject = direction
            item.image = NSImage(systemSymbolName: direction.symbolName, accessibilityDescription: nil)
            item.attributedTitle = detailedTitle(direction.title, direction.detail)
            item.state = direction == current ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let shortcut = actionItem("Phím tắt đổi nhanh \(hotKey.display)", #selector(toggleHotKey))
        shortcut.state = hotKey.isRegistered ? .on : .off
        menu.addItem(shortcut)
        menu.addItem(actionItem("Mở cài đặt Trackpad…", #selector(openTrackpadSettings)))
        menu.addItem(actionItem("Mở cài đặt Chuột…", #selector(openMouseSettings)))
    }

    override func menuDidClose(_ menu: NSMenu) {
        // Detach the menu so the next left click switches instead of opening it.
        statusItem?.menu = nil
    }

    // MARK: - Actions

    private func toggle() {
        apply(ScrollDirection.current.toggled)
    }

    @objc private func chooseDirection(_ sender: NSMenuItem) {
        guard let direction = sender.representedObject as? ScrollDirection else { return }
        apply(direction)
    }

    private func apply(_ direction: ScrollDirection) {
        do {
            try ScrollDirection.apply(direction)
        } catch {
            showAlert("Không đổi được hướng cuộn", error.localizedDescription)
        }
        refreshIcon()
    }

    @objc private func toggleHotKey() {
        UserDefaults.standard.set(!hotKey.isRegistered, forKey: Self.hotKeyKey)
    }

    @objc private func openTrackpadSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Trackpad-Settings.extension")!)
    }

    @objc private func openMouseSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Mouse-Settings.extension")!)
    }
}
