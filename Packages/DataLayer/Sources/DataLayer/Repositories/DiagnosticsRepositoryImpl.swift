import Domain

public struct DiagnosticsRepositoryImpl: DiagnosticsRepository {
    private let client: BridgeClient

    public init(transport: any IoTTransport) {
        self.client = BridgeClient(transport: transport)
    }

    public func bridgeStatus() async throws -> BridgeStatus {
        let payload = try await client.call("bridge.status", params: EmptyParams(), as: StatusData.self)
        return BridgeStatus(isReady: payload.status == "ready", messageCount: payload.messageCount)
    }
}
