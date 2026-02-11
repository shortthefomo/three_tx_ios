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

    // Store the app's current active configuration so the widget can sync
    static func saveActiveConfig(network: XRPLNetwork, dataMode: DataMode) {
        print("💾 SharedStore SAVE ACTIVE CONFIG: network=\(network.shortName), mode=\(dataMode.rawValue)")
        defaults.set(network.rawValue, forKey: "xrpl.activeNetwork")
        defaults.set(dataMode.rawValue, forKey: "xrpl.activeDataMode")
    }

    static func loadActiveConfig() -> (network: XRPLNetwork, dataMode: DataMode) {
        let networkStr = defaults.string(forKey: "xrpl.activeNetwork") ?? XRPLNetwork.xrpl.rawValue
        let modeStr = defaults.string(forKey: "xrpl.activeDataMode") ?? DataMode.live.rawValue
        
        let network = XRPLNetwork(rawValue: networkStr) ?? .xrpl
        let dataMode = DataMode(rawValue: modeStr) ?? .live
        
        print("📖 SharedStore LOAD ACTIVE CONFIG: network=\(network.shortName), mode=\(dataMode.rawValue)")
        return (network, dataMode)
    }

    static func save(_ data: XRPLData, network: XRPLNetwork, dataMode: DataMode) {
        let key = cacheKey(network: network, dataMode: dataMode)
        let timestampKey = "\(key).timestamp"
        print("🔵 SharedStore SAVE: key=\(key), total=\(data.totalTransactions)")
        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: key)
            defaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
            print("✅ SharedStore SAVED successfully to \(suiteName)")
        } catch {
            print("❌ SharedStore SAVE failed: \(error)")
            return
        }
    }

    static func load(network: XRPLNetwork, dataMode: DataMode) -> XRPLData? {
        let key = cacheKey(network: network, dataMode: dataMode)
        print("🟡 SharedStore LOAD: key=\(key) from \(suiteName)")
        guard let data = defaults.data(forKey: key) else {
            print("❌ SharedStore LOAD: key not found in cache")
            return nil
        }

        if let decoded = try? JSONDecoder().decode(XRPLData.self, from: data) {
            print("✅ SharedStore LOADED: total=\(decoded.totalTransactions)")
            return decoded
        } else {
            print("❌ SharedStore LOAD: decode failed")
            return nil
        }
    }

    static func getLastUpdateTime(network: XRPLNetwork, dataMode: DataMode) -> Date? {
        let key = cacheKey(network: network, dataMode: dataMode)
        let timestampKey = "\(key).timestamp"
        if let timeInterval = defaults.object(forKey: timestampKey) as? TimeInterval {
            return Date(timeIntervalSince1970: timeInterval)
        }
        return nil
    }

    static func isCacheStale(network: XRPLNetwork, dataMode: DataMode, maxAge: TimeInterval = 300) -> Bool {
        guard let lastUpdate = getLastUpdateTime(network: network, dataMode: dataMode) else {
            return true // No cache exists
        }
        return Date().timeIntervalSince(lastUpdate) > maxAge
    }
}
