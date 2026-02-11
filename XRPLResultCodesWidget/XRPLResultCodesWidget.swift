import SwiftUI
import WidgetKit

struct XRPLWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: XRPLWidgetConfigurationIntent
    let data: XRPLData?
    let errorMessage: String?
    let isPlaceholder: Bool
}

struct XRPLWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> XRPLWidgetEntry {
        XRPLWidgetEntry(
            date: Date(),
            configuration: XRPLWidgetConfigurationIntent(),
            data: XRPLWidgetEntryView.previewData,
            errorMessage: nil,
            isPlaceholder: true
        )
    }

    func snapshot(for configuration: XRPLWidgetConfigurationIntent, in context: Context) async -> XRPLWidgetEntry {
        // Load real data for snapshot
        let appConfig = XRPLSharedStore.loadActiveConfig()
        let resolvedNetwork = configuration.network ?? appConfig.network
        let resolvedDataMode = configuration.dataMode ?? appConfig.dataMode
        
        let data = await XRPLWidgetDataService().fetchData(
            network: resolvedNetwork,
            dataMode: resolvedDataMode
        )
        
        return XRPLWidgetEntry(
            date: Date(),
            configuration: configuration,
            data: data ?? XRPLWidgetEntryView.previewData,
            errorMessage: nil,
            isPlaceholder: false
        )
    }

    func timeline(for configuration: XRPLWidgetConfigurationIntent, in context: Context) async -> Timeline<XRPLWidgetEntry> {
        // Use widget's explicit config first, then fall back to app's active config
        let appConfig = XRPLSharedStore.loadActiveConfig()
        let resolvedNetwork = configuration.network ?? appConfig.network
        let resolvedDataMode = configuration.dataMode ?? appConfig.dataMode
        
        print("🟣 Widget timeline: using network=\(resolvedNetwork.shortName), mode=\(resolvedDataMode.rawValue)")
        
        let data = await XRPLWidgetDataService().fetchData(
            network: resolvedNetwork,
            dataMode: resolvedDataMode
        )

        let entry = XRPLWidgetEntry(
            date: Date(),
            configuration: configuration,
            data: data,
            errorMessage: data == nil ? "No data available" : nil,
            isPlaceholder: false
        )

        let refreshDate = Date().addingTimeInterval(resolvedDataMode.refreshInterval)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

struct XRPLWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: XRPLWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.black.opacity(0.04))

            content
                .padding(12)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if entry.isPlaceholder {
                placeholderRows
            } else if let data = entry.data {
                summary(for: data)
                dataRows(for: data)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.errorMessage ?? "No data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Open the app to refresh")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 0)

            footer
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text((entry.configuration.displayMode ?? .resultCodes).rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                Text((entry.configuration.network ?? .xrpl).shortName)
                    .font(.headline)
                Text((entry.configuration.dataMode ?? .historical100).rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func summary(for data: XRPLData) -> some View {
        let mode = entry.configuration.displayMode ?? .resultCodes
        let mostCommon = mode == .resultCodes ? data.mostCommonResultCode : data.mostCommonTransactionType

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Total: \(data.totalTransactions)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if let mostCommon = mostCommon {
                    Text("Top: \(mostCommon)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if family != .systemSmall {
                HStack {
                    if (entry.configuration.dataMode ?? .historical100) == .live {
                        Text("Ledger: \(data.latestLedger)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Ledgers: \(data.ledgerRange)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    private func dataRows(for data: XRPLData) -> some View {
        let entries = (entry.configuration.displayMode ?? .resultCodes) == .resultCodes ? data.resultCodes : data.transactionTypes
        let maxRows: Int

        switch family {
        case .systemSmall:
            maxRows = 3
        case .systemMedium:
            maxRows = 4
        case .systemLarge:
            maxRows = 6
        default:
            maxRows = 3
        }

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(entries.prefix(maxRows).enumerated()), id: \.offset) { index, item in
                HStack(spacing: 6) {
                    Text(item.type)
                        .font(.system(.caption2, design: .monospaced))
                        .lineLimit(1)
                    Spacer()
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", item.share))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if family != .systemSmall {
                    ProgressView(value: item.share, total: 100)
                        .tint(barColor(for: index))
                }
            }
        }
    }

    private var placeholderRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<3, id: \.self) { _ in
                HStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 70, height: 8)
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 40, height: 8)
                }
            }
        }
    }

    private var footer: some View {
        Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
            .font(.caption2)
            .foregroundColor(.secondary)
    }

    private func barColor(for index: Int) -> Color {
        let colors: [Color] = [.green, .blue, .orange, .red, .pink, .yellow, .cyan]
        return colors[index % colors.count]
    }

    nonisolated static var previewData: XRPLData {
        XRPLData(
            resultCodes: [
                ResultCodeData(type: "tesSUCCESS", count: 120, share: 62.0),
                ResultCodeData(type: "tecPATH_DRY", count: 40, share: 20.0),
                ResultCodeData(type: "temBAD_AUTH_MASTER", count: 20, share: 10.0),
                ResultCodeData(type: "tecNO_DST", count: 12, share: 8.0)
            ],
            transactionTypes: [
                ResultCodeData(type: "Payment", count: 80, share: 45.0),
                ResultCodeData(type: "OfferCreate", count: 60, share: 32.0),
                ResultCodeData(type: "TrustSet", count: 25, share: 13.0)
            ],
            totalTransactions: 192,
            lastUpdated: ISO8601DateFormatter().string(from: Date()),
            mostCommonResultCode: "tesSUCCESS",
            mostCommonTransactionType: "Payment",
            averageResultCodes: 48.0,
            averageTransactionTypes: 64.0,
            latestLedger: 999999,
            ledgerRange: "999900 to 999999",
            networkName: XRPLNetwork.xrpl.rawValue
        )
    }
}

struct XRPLResultCodesWidget: Widget {
    static let kind = "XRPLResultCodesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: XRPLWidgetConfigurationIntent.self,
            provider: XRPLWidgetProvider()
        ) { entry in
            XRPLWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("XRPL Result Codes")
        .description("Track result codes and transaction types.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct XRPLResultCodesWidgetBundle: WidgetBundle {
    var body: some Widget {
        XRPLResultCodesWidget()
    }
}

#Preview(as: .systemSmall) {
    XRPLResultCodesWidget()
} timeline: {
    XRPLWidgetEntry(
        date: Date(),
        configuration: XRPLWidgetConfigurationIntent(),
        data: XRPLWidgetEntryView.previewData,
        errorMessage: nil,
        isPlaceholder: false
    )
}
