import Foundation

@MainActor
final class XRPLDataService: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedNetwork: XRPLNetwork = .xrpl
    @Published var dataMode: DataMode = .historical100
    @Published var lastDataUpdate = Date()

    private var cachedData: [XRPLNetwork: XRPLData] = [:]
    private var refreshTimer: Timer?
    private var liveClients: [XRPLNetwork: XRPLClient] = [:]

    deinit {
        refreshTimer?.invalidate()
        Task { @MainActor in
            self.stopLiveListeners()
        }
    }

    func getCurrentData() -> XRPLData? {
        cachedData[selectedNetwork]
    }

    func startAutoRefresh() {
        refreshTimer?.invalidate()

        if dataMode == .live {
            stopLiveListeners()
            Task { @MainActor in
                await startLiveListeners()
            }
            return
        }

        stopLiveListeners()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: dataMode.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchAllNetworks()
            }
        }
    }

    private func startLiveListeners() async {
        for network in XRPLNetwork.allCases {
            let client = XRPLClient()
            liveClients[network] = client

            client.onLedgerClosed = { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshLiveData(for: network)
                }
            }

            do {
                try await client.connect(to: network)
                try await client.subscribeToLedgerClosed()
            } catch {
                print("❌ Live subscribe failed for \(network.shortName): \(error)")
            }
        }
    }

    private func stopLiveListeners() {
        for (_, client) in liveClients {
            client.disconnect()
        }
        liveClients.removeAll()
    }

    private func refreshLiveData(for network: XRPLNetwork) async {
        guard dataMode == .live else { return }

        let client = XRPLClient()
        if let data = await fetchResultCodes(for: network, using: client) {
            cachedData[network] = data
            lastDataUpdate = Date()
        }
    }

    func fetchAllNetworks() async -> XRPLData? {
        isLoading = true
        error = nil

        async let xrplTask = fetchResultCodes(for: .xrpl, using: XRPLClient())
        async let xahauTask = fetchResultCodes(for: .xahau, using: XRPLClient())

        let (xrplData, xahauData) = await (xrplTask, xahauTask)

        if let xrplData = xrplData {
            cachedData[.xrpl] = xrplData
        }
        if let xahauData = xahauData {
            cachedData[.xahau] = xahauData
        }

        lastDataUpdate = Date()
        isLoading = false
        return cachedData[selectedNetwork]
    }

    private func fetchResultCodes(for network: XRPLNetwork, using client: XRPLClient) async -> XRPLData? {
        do {
            print("🔄 Starting concurrent fetch for \(network.shortName)")
            try await client.connect(to: network)
            defer {
                client.disconnect()
                print("✅ Completed fetch for \(network.shortName)")
            }

            let ledgerResponse = try await client.request([
                "command": "ledger",
                "ledger_index": "validated"
            ])

            guard let result = ledgerResponse["result"] as? [String: Any],
                  let latestLedger = result["ledger_index"] as? Int else {
                throw XRPLError.invalidResponse
            }

            let startLedger = max(latestLedger - dataMode.ledgerCount + 1, 1)
            let ledgerRange = "\(startLedger) to \(latestLedger)"

            var resultCounts: [String: Int] = [:]
            var transactionTypeCounts: [String: Int] = [:]
            var totalTransactions = 0

            for ledgerIndex in stride(from: latestLedger, through: startLedger, by: -1) {
                do {
                    let transactions = try await fetchLedgerTransactions(ledgerIndex: ledgerIndex, using: client)
                    for tx in transactions {
                        totalTransactions += 1
                        let resultCode = extractResultCode(from: tx)
                        resultCounts[resultCode, default: 0] += 1

                        let transactionType = extractTransactionType(from: tx)
                        transactionTypeCounts[transactionType, default: 0] += 1
                    }
                } catch {
                    print("⚠️ Failed to fetch ledger \(ledgerIndex) for \(network.shortName): \(error)")
                }
            }

            return processResultCounts(resultCounts,
                                       transactionTypeCounts: transactionTypeCounts,
                                       totalTransactions: totalTransactions,
                                       latestLedger: latestLedger,
                                       ledgerRange: ledgerRange,
                                       network: network)

        } catch {
            print("❌ Error fetching \(network.shortName) result codes: \(error)")
            return nil
        }
    }

    private func fetchLedgerTransactions(ledgerIndex: Int, using client: XRPLClient) async throws -> [[String: Any]] {
        let response = try await client.request([
            "command": "ledger",
            "ledger_index": ledgerIndex,
            "transactions": true,
            "expand": true,
            "binary": false
        ])

        guard let result = response["result"] as? [String: Any],
              let ledger = result["ledger"] as? [String: Any],
              let transactions = ledger["transactions"] as? [[String: Any]] else {
            return []
        }

        return transactions
    }

    private func extractResultCode(from tx: [String: Any]) -> String {
        if let meta = tx["meta"] as? [String: Any],
           let result = meta["TransactionResult"] as? String {
            return result
        }

        if let meta = tx["meta"] as? [String: Any],
           let result = meta["transaction_result"] as? String {
            return result
        }

        if let metaData = tx["metaData"] as? [String: Any] {
            if let result = metaData["TransactionResult"] as? String {
                return result
            }
            if let result = metaData["transaction_result"] as? String {
                return result
            }
        }

        return "Unknown"
    }

    private func extractTransactionType(from tx: [String: Any]) -> String {
        if let type = tx["TransactionType"] as? String {
            return type
        }

        if let txJson = tx["tx"] as? [String: Any],
           let type = txJson["TransactionType"] as? String {
            return type
        }

        return "Unknown"
    }

    private func processResultCounts(_ counts: [String: Int],
                                     transactionTypeCounts: [String: Int],
                                     totalTransactions: Int,
                                     latestLedger: Int,
                                     ledgerRange: String,
                                     network: XRPLNetwork) -> XRPLData {
        let resultEntries = counts.sorted { $0.value > $1.value }
        let typeEntries = transactionTypeCounts.sorted { $0.value > $1.value }

        let resultCodes = resultEntries.map { (type, count) in
            ResultCodeData(
                type: type,
                count: count,
                share: totalTransactions > 0 ? Double(count) / Double(totalTransactions) * 100 : 0
            )
        }

        let transactionTypes = typeEntries.map { (type, count) in
            ResultCodeData(
                type: type,
                count: count,
                share: totalTransactions > 0 ? Double(count) / Double(totalTransactions) * 100 : 0
            )
        }

        let mostCommonResultCode = resultEntries.first?.key
        let mostCommonTransactionType = typeEntries.first?.key
        let averageResultCodes = resultEntries.isEmpty ? 0 : Double(totalTransactions) / Double(resultEntries.count)
        let averageTransactionTypes = typeEntries.isEmpty ? 0 : Double(totalTransactions) / Double(typeEntries.count)

        return XRPLData(
            resultCodes: resultCodes,
            transactionTypes: transactionTypes,
            totalTransactions: totalTransactions,
            lastUpdated: ISO8601DateFormatter().string(from: Date()),
            mostCommonResultCode: mostCommonResultCode,
            mostCommonTransactionType: mostCommonTransactionType,
            averageResultCodes: averageResultCodes,
            averageTransactionTypes: averageTransactionTypes,
            latestLedger: latestLedger,
            ledgerRange: ledgerRange,
            networkName: network.rawValue
        )
    }
}
