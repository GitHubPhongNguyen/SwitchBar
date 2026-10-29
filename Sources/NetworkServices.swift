import Foundation
import SystemConfiguration

struct NetworkService {
    enum Kind {
        case wifi, ethernet, iphone, other

        var symbolName: String {
            switch self {
            case .wifi: "wifi"
            case .ethernet: "cable.connector"
            case .iphone: "iphone"
            case .other: "network"
            }
        }
    }

    let id: String
    let name: String
    let kind: Kind
    let enabled: Bool
    /// Routable IPv4 address, nil when the service is not connected.
    let address: String?

    var isConnected: Bool { enabled && address != nil }
}

enum NetworkServices {
    struct SwitchError: LocalizedError {
        let errorDescription: String?
    }

    /// All services of the current network location, highest priority first.
    static func load() -> [NetworkService] {
        guard let prefs = SCPreferencesCreate(nil, "SwitchBar" as CFString, nil),
              let set = SCNetworkSetCopyCurrent(prefs),
              let services = SCNetworkSetCopyServices(set) as? [SCNetworkService]
        else { return [] }

        let order = SCNetworkSetGetServiceOrder(set) as? [String] ?? []
        let rank = Dictionary(order.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        let store = SCDynamicStoreCreate(nil, "SwitchBar" as CFString, nil, nil)

        return services
            .compactMap { service -> NetworkService? in
                guard let id = SCNetworkServiceGetServiceID(service) as String?,
                      let name = SCNetworkServiceGetName(service) as String?,
                      !isHidden(id, in: prefs)
                else { return nil }
                return NetworkService(
                    id: id,
                    name: name,
                    kind: kind(of: SCNetworkServiceGetInterface(service)),
                    enabled: SCNetworkServiceGetEnabled(service),
                    address: address(of: id, in: store)
                )
            }
            .sorted { (rank[$0.id] ?? .max, $0.name) < (rank[$1.id] ?? .max, $1.name) }
    }

    /// Moves `name` to the top of the service order; the others keep their relative order.
    static func prioritize(_ name: String) throws {
        let current = load().map(\.name)
        let order = [name] + current.filter { $0 != name }

        var output = run(order)
        if load().first?.name != name {
            // Admin accounts can normally reorder without a password; fall back to asking for one.
            output = runAsAdmin(order) ?? output
        }
        guard load().first?.name == name else {
            throw SwitchError(errorDescription: output.isEmpty ? "macOS không áp dụng thứ tự mới." : output)
        }
    }

    /// System-internal services (e.g. "Ethernet Adapter (en4)") that System Settings and networksetup don't show.
    private static func isHidden(_ serviceID: String, in prefs: SCPreferences) -> Bool {
        let interface = SCPreferencesPathGetValue(prefs, "/NetworkServices/\(serviceID)/Interface" as CFString) as? [String: Any]
        return interface?["HiddenConfiguration"] as? Bool ?? false
    }

    private static func kind(of interface: SCNetworkInterface?) -> NetworkService.Kind {
        guard let interface, let type = SCNetworkInterfaceGetInterfaceType(interface) else { return .other }
        if type == kSCNetworkInterfaceTypeIEEE80211 { return .wifi }
        let displayName = SCNetworkInterfaceGetLocalizedDisplayName(interface) as String? ?? ""
        if displayName.contains("iPhone") { return .iphone }
        if type == kSCNetworkInterfaceTypeEthernet { return .ethernet }
        return .other
    }

    private static func address(of serviceID: String, in store: SCDynamicStore?) -> String? {
        let key = "State:/Network/Service/\(serviceID)/IPv4" as CFString
        guard let state = SCDynamicStoreCopyValue(store, key) as? [String: Any],
              let addresses = state["Addresses"] as? [String]
        else { return nil }
        // Self-assigned link-local addresses mean no real network behind the interface.
        return addresses.first { !$0.hasPrefix("169.254.") }
    }

    private static let networksetup = "/usr/sbin/networksetup"

    private static func run(_ order: [String]) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: networksetup)
        process.arguments = ["-ordernetworkservices"] + order
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            return error.localizedDescription
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns nil when the user cancels the password prompt.
    private static func runAsAdmin(_ order: [String]) -> String? {
        let command = ([networksetup, "-ordernetworkservices"] + order).map(shellQuoted).joined(separator: " ")
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        var error: NSDictionary?
        let result = NSAppleScript(source: "do shell script \"\(escaped)\" with administrator privileges")?
            .executeAndReturnError(&error)
        if let error {
            return error[NSAppleScript.errorNumber] as? Int == -128 ? nil : "\(error[NSAppleScript.errorMessage] ?? error)"
        }
        return result?.stringValue ?? ""
    }

    private static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
