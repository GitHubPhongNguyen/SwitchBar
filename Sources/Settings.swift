import AppKit
import ServiceManagement
import SwiftUI

final class SettingsWindowController {
    private let modules: [MenuBarModule]
    private let hotKeyDisplay: String
    private let window: NSWindow

    init(modules: [MenuBarModule], hotKeyDisplay: String) {
        self.modules = modules
        self.hotKeyDisplay = hotKeyDisplay
        window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: true)
        window.title = "Cài đặt SwitchBar"
        window.isReleasedWhenClosed = false
    }

    func show() {
        if !window.isVisible {
            // A fresh view each time so it picks up changes made elsewhere, e.g. Login Items in System Settings.
            window.contentViewController = NSHostingController(rootView: SettingsView(modules: modules, hotKeyDisplay: hotKeyDisplay))
            window.center()
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}

private struct SettingsView: View {
    let modules: [MenuBarModule]
    let hotKeyDisplay: String
    @AppStorage(ScrollModule.hotKeyKey) private var hotKeyEnabled = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                ForEach(modules, id: \.id) { ModuleRow(module: $0) }
            } header: {
                Text("Hiện trên thanh menu")
            } footer: {
                Text("Ẩn hết icon cũng không sao: mở lại SwitchBar từ Applications hoặc Spotlight để quay về cửa sổ này.")
                    .foregroundStyle(.secondary)
            }
            Section {
                Toggle(isOn: $hotKeyEnabled) {
                    Text("Phím tắt \(hotKeyDisplay) để đổi hướng cuộn")
                    Text("Dùng được cả khi đã ẩn icon Hướng cuộn")
                }
                Toggle("Mở cùng máy", isOn: $launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize()
        .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        guard enabled != (service.status == .enabled) else { return }
        do {
            if enabled {
                try service.register()
                if service.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
            } else {
                try service.unregister()
            }
        } catch {
            showAlert("Không đổi được cài đặt mở cùng máy", error.localizedDescription)
        }
        launchAtLogin = service.status == .enabled
    }
}

private struct ModuleRow: View {
    let module: MenuBarModule
    @AppStorage private var isShown: Bool

    init(module: MenuBarModule) {
        self.module = module
        _isShown = AppStorage(wrappedValue: true, module.visibilityKey)
    }

    var body: some View {
        Toggle(isOn: $isShown) {
            HStack(spacing: 10) {
                Image(systemName: module.symbolName)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(module.title)
                    Text(module.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
