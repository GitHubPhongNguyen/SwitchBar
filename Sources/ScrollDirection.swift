import Foundation

/// The "Natural scrolling" setting. macOS keeps a single value shared by trackpads and mice.
enum ScrollDirection {
    case natural, traditional

    var title: String {
        switch self {
        case .natural: "Tự nhiên"
        case .traditional: "Kiểu chuột"
        }
    }

    var detail: String {
        switch self {
        case .natural: "nội dung chạy theo ngón tay"
        case .traditional: "lăn xuống là trang đi xuống"
        }
    }

    var symbolName: String {
        switch self {
        case .natural: "hand.draw"
        case .traditional: "computermouse"
        }
    }

    var toggled: ScrollDirection { self == .natural ? .traditional : .natural }

    /// Posted by macOS after every change, including ones made in System Settings.
    static let didChangeNotification = Notification.Name("SwipeScrollDirectionDidChangeNotification")

    struct SwitchError: LocalizedError {
        let errorDescription: String?
    }

    static var current: ScrollDirection {
        var exists: DarwinBoolean = false
        let natural = CFPreferencesGetAppBooleanValue(key, kCFPreferencesAnyApplication, &exists)
        // The key stays unset until the user first changes the setting, and macOS defaults to natural.
        return natural || !exists.boolValue ? .natural : .traditional
    }

    static func apply(_ direction: ScrollDirection) throws {
        guard let setSwipeScrollDirection else {
            throw SwitchError(errorDescription: "Phiên bản macOS này không cho app đổi hướng cuộn. Hãy đổi trong Cài đặt hệ thống.")
        }
        setSwipeScrollDirection(direction == .natural)
        guard current == direction else {
            throw SwitchError(errorDescription: "macOS không áp dụng hướng cuộn mới.")
        }
    }

    private static let key = "com.apple.swipescrolldirection" as CFString

    /// Private function from the framework behind the Trackpad and Mouse settings panes. Unlike
    /// `defaults write`, it takes effect at once without logging out; it also saves the value and
    /// posts `didChangeNotification`.
    private static let setSwipeScrollDirection: (@convention(c) (Bool) -> Void)? = {
        guard let framework = dlopen("/System/Library/PrivateFrameworks/PreferencePanesSupport.framework/PreferencePanesSupport", RTLD_LAZY),
              let symbol = dlsym(framework, "setSwipeScrollDirection")
        else { return nil }
        return unsafeBitCast(symbol, to: (@convention(c) (Bool) -> Void).self)
    }()
}
