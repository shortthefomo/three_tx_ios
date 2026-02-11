import Foundation
import AppIntents

struct ResultCodeData: Codable {
    let type: String
    let count: Int
    let share: Double
}

struct XRPLData: Codable {
    let resultCodes: [ResultCodeData]
    let transactionTypes: [ResultCodeData]
    let totalTransactions: Int
    let lastUpdated: String
    let mostCommonResultCode: String?
    let mostCommonTransactionType: String?
    let averageResultCodes: Double
    let averageTransactionTypes: Double
    let latestLedger: Int
    let ledgerRange: String
    let networkName: String
}

enum DisplayMode: String, CaseIterable {
    case resultCodes = "Result Codes"
    case transactionTypes = "Tx Types"
}

enum DataMode: String, CaseIterable {
    case live = "Live"
    case historical100 = "Last 100"

    var ledgerCount: Int {
        switch self {
        case .live:
            return 1
        case .historical100:
            return 100
        }
    }

    var refreshInterval: TimeInterval {
        switch self {
        case .live:
            return 15
        case .historical100:
            return 300
        }
    }
}

enum XRPLNetwork: String, CaseIterable {
    case xrpl = "XRPL Mainnet"
    case xahau = "Xahau Network"

    var wsURL: String {
        switch self {
        case .xrpl:
            return "wss://xrpl1.panicbot.app"
        case .xahau:
            return "wss://xahau2.panicbot.app"
        }
    }

    var shortName: String {
        switch self {
        case .xrpl:
            return "XRPL"
        case .xahau:
            return "Xahau"
        }
    }
}

enum XRPLError: Error, LocalizedError {
    case invalidURL
    case notConnected
    case serverError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .notConnected:
            return "Not connected to XRPL"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

extension XRPLNetwork: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Network")
    }

    static var caseDisplayRepresentations: [XRPLNetwork: DisplayRepresentation] {
        [
            .xrpl: DisplayRepresentation(title: "XRPL", subtitle: "XRPL Mainnet"),
            .xahau: DisplayRepresentation(title: "Xahau", subtitle: "Xahau Network")
        ]
    }
}

extension DisplayMode: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "View")
    }

    static var caseDisplayRepresentations: [DisplayMode: DisplayRepresentation] {
        [
            .resultCodes: DisplayRepresentation(title: "Result Codes"),
            .transactionTypes: DisplayRepresentation(title: "Tx Types")
        ]
    }
}

extension DataMode: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Data")
    }

    static var caseDisplayRepresentations: [DataMode: DisplayRepresentation] {
        [
            .live: DisplayRepresentation(title: "Live"),
            .historical100: DisplayRepresentation(title: "Last 100")
        ]
    }
}
