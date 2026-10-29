import AppKit
import SystemConfiguration

/// Picks which network macOS prefers (Wi-Fi ↔ Ethernet) without going through Set Service Order.
final class NetworkModule: MenuBarModule {
    private var store: SCDynamicStore?

    init() {
        super.init(id: "network", title: "Ưu tiên mạng", summary: "Đổi nhanh giữa Wi-Fi và dây cáp", symbolName: "network")
    }

    override func didShow(_ item: NSStatusItem) {
        item.menu = menu
        watchNetworkChanges()
        refreshIcon()
    }

    override func willHide() {
        if let store {
            SCDynamicStoreSetDispatchQueue(store, nil)
        }
        store = nil
    }

    // MARK: - Status bar icon

    fileprivate func refreshIcon() {
        guard let button = statusItem?.button else { return }
        let active = NetworkServices.load().first(where: \.isConnected)
        let image = NSImage(
            systemSymbolName: active?.kind.symbolName ?? "wifi.slash",
            accessibilityDescription: active?.name ?? "Không có mạng"
        )
        image?.isTemplate = true
        button.image = image
        button.toolTip = active.map { "Đang ưu tiên: \($0.name)" } ?? "Không có mạng nào đang kết nối"
    }

    /// Refreshes the icon whenever the service order or any connection changes, including edits made in System Settings.
    private func watchNetworkChanges() {
        var context = SCDynamicStoreContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil
        )
        store = SCDynamicStoreCreate(nil, "SwitchBar" as CFString, { _, _, info in
            guard let info else { return }
            let module = Unmanaged<NetworkModule>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async { module.refreshIcon() }
        }, &context)
        guard let store else { return }
        SCDynamicStoreSetNotificationKeys(
            store,
            ["Setup:/Network/Global/IPv4", "State:/Network/Global/IPv4"] as CFArray,
            ["State:/Network/Service/.*/IPv4"] as CFArray
        )
        SCDynamicStoreSetDispatchQueue(store, .main)
    }

    // MARK: - Menu

    override func buildMenu(_ menu: NSMenu) {
        let services = NetworkServices.load()
        let connected = services.filter(\.isConnected)
        let others = services.filter { !$0.isConnected }

        menu.addItem(.sectionHeader(title: "Ưu tiên mạng"))
        if connected.isEmpty {
            let empty = NSMenuItem(title: "Không có mạng nào đang kết nối", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        }
        for (index, service) in connected.enumerated() {
            let item = serviceItem(service)
            item.state = index == 0 ? .on : .off
            menu.addItem(item)
        }

        if !others.isEmpty {
            let submenu = NSMenu()
            others.forEach { submenu.addItem(serviceItem($0)) }
            let item = NSMenuItem(title: "Mạng khác", action: nil, keyEquivalent: "")
            item.submenu = submenu
            menu.addItem(.separator())
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(actionItem("Mở cài đặt Mạng…", #selector(openNetworkSettings)))
    }

    private func serviceItem(_ service: NetworkService) -> NSMenuItem {
        let item = actionItem(service.name, #selector(prioritize(_:)))
        item.representedObject = service.name
        item.image = NSImage(systemSymbolName: service.kind.symbolName, accessibilityDescription: nil)
        let detail = service.address ?? (service.enabled ? "chưa kết nối" : "đã tắt")
        item.attributedTitle = detailedTitle(service.name, detail)
        return item
    }

    // MARK: - Actions

    @objc private func prioritize(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        do {
            try NetworkServices.prioritize(name)
        } catch {
            showAlert("Không đổi được thứ tự mạng", error.localizedDescription)
        }
        refreshIcon()
    }

    @objc private func openNetworkSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension")!)
    }
}
