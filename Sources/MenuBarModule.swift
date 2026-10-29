import AppKit

/// One tool with its own icon in the menu bar. Settings shows or hides each icon independently.
class MenuBarModule: NSObject, NSMenuDelegate {
    let id: String
    let title: String
    let summary: String
    let symbolName: String
    let menu = NSMenu()
    private(set) var statusItem: NSStatusItem?

    var visibilityKey: String { "show.\(id)" }

    init(id: String, title: String, summary: String, symbolName: String) {
        self.id = id
        self.title = title
        self.summary = summary
        self.symbolName = symbolName
        super.init()
        menu.delegate = self
    }

    func setVisible(_ visible: Bool) {
        if visible, statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            // Ties the position the user ⌘-drags the icon to to this module, not to creation order.
            item.autosaveName = id
            item.isVisible = true
            statusItem = item
            didShow(item)
        } else if !visible, let item = statusItem {
            willHide()
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    // MARK: - Subclass hooks

    /// Sets up the icon and whatever keeps it up to date.
    func didShow(_ item: NSStatusItem) {}

    func willHide() {}

    /// Adds the module's own items; the shared footer goes after them.
    func buildMenu(_ menu: NSMenu) {}

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        buildMenu(menu)
        menu.addItem(.separator())
        menu.addItem(actionItem("Ẩn icon này", #selector(hideIcon)))
        menu.addItem(NSMenuItem(title: "Cài đặt SwitchBar…", action: #selector(AppDelegate.showSettings(_:)), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Thoát SwitchBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    func menuDidClose(_ menu: NSMenu) {}

    func actionItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    /// A menu item showing `title` followed by a smaller grey `detail`.
    func detailedTitle(_ title: String, _ detail: String) -> NSAttributedString {
        let text = NSMutableAttributedString(string: title, attributes: [.font: NSFont.menuFont(ofSize: 0)])
        text.append(NSAttributedString(string: "   \(detail)", attributes: [
            .font: NSFont.menuFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]))
        return text
    }

    @objc private func hideIcon() {
        UserDefaults.standard.set(false, forKey: visibilityKey)
    }
}

func showAlert(_ message: String, _ info: String) {
    NSApp.activate()
    let alert = NSAlert()
    alert.messageText = message
    alert.informativeText = info
    alert.runModal()
}
