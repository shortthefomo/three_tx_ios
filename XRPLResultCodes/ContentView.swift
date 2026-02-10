import SwiftUI

struct ContentView: View {
    @StateObject private var dataService = XRPLDataService()
    @State private var data: XRPLData?
    @State private var displayMode: DisplayMode = .resultCodes
    @State private var showFilters = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DisclosureGroup("Filters", isExpanded: $showFilters) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Network")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Picker("", selection: $dataService.selectedNetwork) {
                            ForEach(XRPLNetwork.allCases, id: \.self) { network in
                                Text(network.shortName)
                                    .tag(network)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .disabled(dataService.isLoading)
                        .onChange(of: dataService.selectedNetwork) { oldValue, newValue in
                            if oldValue != newValue {
                                updateDisplayData()
                                if dataService.getCurrentData() == nil {
                                    Task {
                                        await refreshData()
                                    }
                                }
                            }
                        }

                        Text("View")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Picker("", selection: $displayMode) {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Text("Data")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Picker("", selection: $dataService.dataMode) {
                            ForEach(DataMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .onChange(of: dataService.dataMode) { _, _ in
                            dataService.startAutoRefresh()
                            Task {
                                await refreshData()
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                if let error = dataService.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }

                if let data = data {
                    let entries = displayMode == .resultCodes ? data.resultCodes : data.transactionTypes
                    let mostCommon = displayMode == .resultCodes ? data.mostCommonResultCode : data.mostCommonTransactionType
                    let average = displayMode == .resultCodes ? data.averageResultCodes : data.averageTransactionTypes

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Total: \(data.totalTransactions)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if let mostCommon = mostCommon {
                                Text("Top: \(mostCommon)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Text("Network: \(data.networkName)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            if dataService.dataMode == .live {
                                Text("Ledger: \(data.latestLedger)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Ledgers: \(data.ledgerRange)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    if entries.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No transactions found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(entries.enumerated()), id: \.offset) { index, resultCode in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(resultCode.type)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(resultCode.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("(\(String(format: "%.1f", resultCode.share))%)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    ProgressView(value: resultCode.share, total: 100)
                                        .tint(barColor(for: index))
                                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                                }
                            }
                        }
                    }

                    Divider()

                    HStack {
                        Text("Updated: \(formatDate(data.lastUpdated))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        if average > 0 {
                            Text("Avg: \(String(format: "%.1f", average))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                } else if dataService.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Fetching \(dataService.selectedNetwork.shortName) \(dataService.dataMode.rawValue.lowercased()) data...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Connecting to \(dataService.selectedNetwork.rawValue)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "network")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Ready to fetch \(dataService.selectedNetwork.shortName) data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Start Loading") {
                            Task {
                                await refreshData()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await refreshData() }
                } label: {
                    if dataService.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(dataService.isLoading)
            }
        }
        .onAppear {
            updateDisplayData()
            Task { await refreshData() }
            dataService.startAutoRefresh()
        }
        .onChange(of: dataService.lastDataUpdate) { _, _ in
            updateDisplayData()
        }
    }

    @MainActor
    private func updateDisplayData() {
        data = dataService.getCurrentData()
    }

    @MainActor
    private func refreshData() async {
        if let newData = await dataService.fetchAllNetworks() {
            data = newData
        }
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .short
            displayFormatter.dateStyle = .none
            return displayFormatter.string(from: date)
        }
        return "Unknown"
    }

    private func barColor(for index: Int) -> Color {
        let colors: [Color] = [.green, .blue, .orange, .red, .purple, .pink, .yellow, .cyan]
        return colors[index % colors.count]
    }
}
