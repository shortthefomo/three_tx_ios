import Foundation

struct XRPLWidgetDataService {
    func fetchData(network: XRPLNetwork, dataMode: DataMode) async -> XRPLData? {
        print("🟣 Widget fetchData called: network=\(network.shortName), mode=\(dataMode.rawValue)")
        
        // Load cached data
        if let cachedData = XRPLSharedStore.load(network: network, dataMode: dataMode) {
            // Check if data is stale
            if isDataStale(cachedData, dataMode: dataMode) {
                print("⏳ Widget: Cached data is stale (consider opening the app to refresh)")
            } else {
                print("✅ Widget: Loaded fresh cached data, total=\(cachedData.totalTransactions)")
            }
            return cachedData
        }
        
        print("❌ Widget: No cached data found")
        return nil
    }
    
    private func isDataStale(_ data: XRPLData, dataMode: DataMode) -> Bool {
        // Parse lastUpdated timestamp
        let formatter = ISO8601DateFormatter()
        guard let lastUpdateDate = formatter.date(from: data.lastUpdated) else {
            return true  // If we can't parse date, consider it stale
        }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdateDate)
        let staleThreshold = dataMode.refreshInterval * 1.5  // Consider stale if 1.5x refresh interval has passed
        
        return timeSinceUpdate > staleThreshold
    }
}
