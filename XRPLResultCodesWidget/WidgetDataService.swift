import Foundation

struct XRPLWidgetDataService {
    func fetchData(network: XRPLNetwork, dataMode: DataMode) async -> XRPLData? {
        print("🟣 Widget fetchData called: network=\(network.shortName), mode=\(dataMode.rawValue)")
        let result = XRPLSharedStore.load(network: network, dataMode: dataMode)
        if result != nil {
            print("🟢 Widget fetchData: FOUND cached data")
        } else {
            print("🔴 Widget fetchData: NO cached data found")
        }
        return result
    }
}
