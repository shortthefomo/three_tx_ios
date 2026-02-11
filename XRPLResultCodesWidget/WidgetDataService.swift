import Foundation

struct XRPLWidgetDataService {
    func fetchData(network: XRPLNetwork, dataMode: DataMode) async -> XRPLData? {
        let client = XRPLClient()

        do {
            try await client.connect(to: network)
            defer { client.disconnect() }

            let ledgerResponse = try await client.request([
                "command": "ledger",
                "ledger_index": "validated"
            ])

            guard let result = ledgerResponse["result"] as? [String: Any],
                  let latestLedger = result["ledger_index"] as? Int else {
                throw XRPLError.invalidResponse
            }

            let ledgerCount = min(dataMode.ledgerCount, 3)
            let startLedger = max(latestLedger - ledgerCount + 1, 1)
            let ledgerRange = "\(startLedger) to \(latestLedger)"

            var resultCounts: [String: Int] = [:]
            var transactionTypeCounts: [String: Int] = [:]
            var totalTransactions = 0

            for ledgerIndex in stride(from: latestLedger, through: startLedger, by: -1) {
                let transactions = try await fetchLedgerTransactions(ledgerIndex: ledgerIndex, using: client)
                for tx in transactions {
                    totalTransactions += 1
                    let resultCode = extractResultCode(from: tx)
                    resultCounts[resultCode, default: 0] += 1

                    let transactionType = extractTransactionType(from: tx)
                    transactionTypeCounts[transactionType, default: 0] += 1
                }
            }

            return processResultCounts(
                resultCounts,
                transactionTypeCounts: transactionTypeCounts,
                totalTransactions: totalTransactions,
                latestLedger: latestLedger,
                ledgerRange: ledgerRange,
                network: network
            )
        } catch {
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
