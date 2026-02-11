import AppIntents

struct XRPLWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "XRPL Widget"
    static let description = IntentDescription("Choose the network and view for this widget.")

    @Parameter(title: "Network")
    var network: XRPLNetwork?

    @Parameter(title: "View")
    var displayMode: DisplayMode?

    @Parameter(title: "Data")
    var dataMode: DataMode?

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$network
            \.$displayMode
            \.$dataMode
        }
    }

    init() {}
}
