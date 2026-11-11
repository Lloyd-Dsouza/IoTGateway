public struct FetchBridgeStatusUseCase: Sendable {
    private let repository: any DiagnosticsRepository
    public init(repository: any DiagnosticsRepository) {
        self.repository = repository
    }

    public func execute() async throws -> BridgeStatus {
        try await repository.bridgeStatus()
    }
}
