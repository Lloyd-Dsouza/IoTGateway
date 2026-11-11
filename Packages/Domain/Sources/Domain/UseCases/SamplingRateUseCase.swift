public struct UpdateSamplingRateUseCase: Sendable {
    private let repository: any DeviceRepository
    public init(repository: any DeviceRepository) { self.repository = repository }

    public func execute(deviceId: DeviceID, rate: Int) async throws -> SamplingRateResult {
        guard DeviceLimits.samplingRateSeconds.contains(rate) else {
            throw DomainError.invalidValue(DomainMessages.samplingRateRange)
        }
        return try await repository.updateSamplingRate(deviceId: deviceId, rateSeconds: rate)
    }
}
