import Foundation

struct XRPLWidgetDataService {
    func fetchData(network: XRPLNetwork, dataMode: DataMode) async -> XRPLData? {
        XRPLSharedStore.load(network: network, dataMode: dataMode)
    }
}
