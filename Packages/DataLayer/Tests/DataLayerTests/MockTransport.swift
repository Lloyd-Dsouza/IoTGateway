import DataLayer
import Foundation

/// Pretends to be Flutter. You give it a closure that decides what each method returns.
final class MockTransport: IoTTransport, @unchecked Sendable {
    typealias Responder = (_ method: String, _ params: [String: Any]) throws -> [String: Any]

    private let responder: Responder
    private(set) var lastMethod: String?
    private(set) var lastParams: [String: Any] = [:]

    init(_ responder: @escaping Responder) {
        self.responder = responder
    }

    func send(_ request: Data) async throws -> Data {
        guard let json = try JSONSerialization.jsonObject(with: request) as? [String: Any],
            let method = json["method"] as? String,
            let requestId = json["requestId"] as? String
        else {
            throw BridgeError.malformedResponse
        }
        let params = json["params"] as? [String: Any] ?? [:]
        lastMethod = method
        lastParams = params

        let data = try responder(method, params)

        let envelope: [String: Any] = [
            "requestId": requestId,
            "data": data
        ]
        return try JSONSerialization.data(withJSONObject: envelope)
    }
}
