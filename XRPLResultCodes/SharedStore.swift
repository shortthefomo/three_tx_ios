import Foundation

struct XRPLSharedStore {
    static let suiteName = "group.com.three.xrplresultcodes"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    private static func cacheKey(network: XRPLNetwork, dataMode: DataMode) -> String {
        let safeNetwork = network.shortName.replacingOccurrences(of: " ", with: "-")
        let safeMode = dataMode.rawValue.replacingOccurrences(of: " ", with: "-")
        return "xrpl.cache.\(safeNetwork).\(safeMode)"
    }

    static func save(_ data: XRPLData, network: XRPLNetwork, dataMode: DataMode) {
        let key = cacheKey(network: network, dataMode: dataMode)
        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: key)
        } catch {
            return
        }
    }

    static func load(network: XRPLNetwork, dataMode: DataMode) -> XRPLData? {
        let key = cacheKey(network: network, dataMode: dataMode)
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(XRPLData.self, from: data)
    }
}
