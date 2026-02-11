import Foundation

struct XRPLWidgetDataService {
    func fetchData(network: XRPLNetwork, dataMode: DataMode) async -> XRPLData? {
        print("🟣 Widget fetchData called: network=\(network.shortName), mode=\(dataMode.rawValue)")
        
        // Check cache and load whatever we have
        if let cachedData = XRPLSharedStore.load(network: network, dataMode: dataMode) {
            print("✅ Widget: Loaded cached data, total=\(cachedData.totalTransactions)")
            return cachedData
        }
        
        print("❌ Widget: No cached data found")
        return nil
    }
}
