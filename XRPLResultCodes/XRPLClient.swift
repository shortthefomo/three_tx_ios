import Foundation

final class XRPLClient: NSObject, ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var isConnected = false
    private var requestId = 0
    private var pendingRequests: [Int: (Result<[String: Any], Error>) -> Void] = [:]
    var onLedgerClosed: ((Int) -> Void)?

    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func connect(to network: XRPLNetwork) async throws {
        guard let url = URL(string: network.wsURL) else {
            throw XRPLError.invalidURL
        }

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()

        // Start listening for messages
        receiveMessage()

        // Wait a bit for connection to establish
        try await Task.sleep(nanoseconds: 1_000_000_000)
        isConnected = true
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        pendingRequests.removeAll()
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }

                self?.receiveMessage()

            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        if let id = json["id"] as? Int,
           let completion = pendingRequests[id] {
            pendingRequests.removeValue(forKey: id)

            if let error = json["error"] as? [String: Any] {
                completion(.failure(XRPLError.serverError(error["error_message"] as? String ?? "Unknown error")))
            } else {
                completion(.success(json))
            }
            return
        }

        if let type = json["type"] as? String, type == "ledgerClosed" {
            if let ledgerIndex = json["ledger_index"] as? Int {
                onLedgerClosed?(ledgerIndex)
            } else if let ledgerString = json["ledger_index"] as? String,
                      let ledgerIndex = Int(ledgerString) {
                onLedgerClosed?(ledgerIndex)
            }
        }
    }

    func request(_ command: [String: Any]) async throws -> [String: Any] {
        guard isConnected else {
            throw XRPLError.notConnected
        }

        requestId += 1
        var requestData = command
        requestData["id"] = requestId

        let jsonData = try JSONSerialization.data(withJSONObject: requestData)
        let message = URLSessionWebSocketTask.Message.string(String(data: jsonData, encoding: .utf8)!)

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[requestId] = { result in
                continuation.resume(with: result)
            }

            webSocketTask?.send(message) { error in
                if let error = error {
                    self.pendingRequests.removeValue(forKey: self.requestId)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func subscribeToLedgerClosed() async throws {
        _ = try await request([
            "command": "subscribe",
            "streams": ["ledger"]
        ])
    }
}

extension XRPLClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
        isConnected = true
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
        isConnected = false
    }
}
