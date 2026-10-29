import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let network = NetworkModule()
    private let scroll = ScrollModule()
    private lazy var modules: [MenuBarModule] = [network, scroll]
    private lazy var settings = SettingsWindowController(modules: modules, hotKeyDisplay: scroll.hotKey.display)

    func applicationDidFinishLaunching(_ notification: Notification) {
        var defaults: [String: Any] = [ScrollModule.hotKeyKey: true]
        modules.forEach { defaults[$0.visibilityKey] = true }
        UserDefaults.standard.register(defaults: defaults)

        installKeyboardShortcuts()
        enableLaunchAtLoginOnFirstRun()
        applySettings()
        // Posted on whichever thread wrote the default, and also for writes made while applySettings runs
        // (a refused shortcut turns its setting off), so handle it on a later main-loop turn.
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async { self?.applySettings() }
        }

        // With every icon hidden nothing would show up, so open Settings instead.
        if modules.allSatisfy({ $0.statusItem == nil }) {
            showSettings(nil)
        }
    }

    /// Opening the app again (Applications, Spotlight, Launchpad) brings up Settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings(nil)
        return false
    }

    /// Settings, the icons' menus and the shortcut all write to UserDefaults; this brings the menu bar in line.
    private func applySettings() {
        let defaults = UserDefaults.standard
        modules.forEach { $0.setVisible(defaults.bool(forKey: $0.visibilityKey)) }
        scroll.setHotKeyEnabled(defaults.bool(forKey: ScrollModule.hotKeyKey))
    }

    @objc func showSettings(_ sender: Any?) {
        settings.show()
    }

    /// The app shows no menu bar of its own, but these key equivalents still work while Settings is in front.
    private func installKeyboardShortcuts() {
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Đóng cửa sổ", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        appMenu.addItem(NSMenuItem(title: "Thoát SwitchBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        NSApp.mainMenu = NSMenu()
        NSApp.mainMenu?.addItem(appItem)
    }

    private func enableLaunchAtLoginOnFirstRun() {
        let key = "didSetUpLaunchAtLogin"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        try? SMAppService.mainApp.register()
    }
}
