import Carbon.HIToolbox

/// A system-wide keyboard shortcut. Carbon hot keys fire while any app is in front and,
/// unlike key event monitors, don't need Accessibility permission.
final class HotKey {
    let display: String
    var onPress: (() -> Void)?
    var isRegistered: Bool { ref != nil }

    private let keyCode: Int
    private let modifiers: Int
    private var ref: EventHotKeyRef?

    init(keyCode: Int, modifiers: Int, display: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.display = display

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, info in
            guard let info else { return OSStatus(eventNotHandledErr) }
            Unmanaged<HotKey>.fromOpaque(info).takeUnretainedValue().onPress?()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    /// Returns false when macOS refuses the shortcut, e.g. because another app already owns it.
    @discardableResult
    func register() -> Bool {
        guard ref == nil else { return true }
        var newRef: EventHotKeyRef?
        let id = EventHotKeyID(signature: OSType(0x5343_524C), id: 1) // "SCRL"
        guard RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &newRef) == noErr
        else { return false }
        ref = newRef
        return true
    }

    func unregister() {
        guard let ref else { return }
        UnregisterEventHotKey(ref)
        self.ref = nil
    }
}
