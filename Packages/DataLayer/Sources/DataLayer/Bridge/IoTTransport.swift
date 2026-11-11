import Foundation

public protocol IoTTransport: Sendable {
    func send(_ request: Data) async throws -> Data
}
