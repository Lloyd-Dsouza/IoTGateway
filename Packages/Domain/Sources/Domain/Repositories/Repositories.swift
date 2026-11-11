// MARK: Device repository

public protocol DeviceRepository: Sendable {
    func fetchDevices() async throws -> [Device]
    func device(id: DeviceID) async throws -> Device
    func send(_ command: DeviceCommand, to deviceId: DeviceID) async throws -> Device
    func updateSamplingRate(deviceId: DeviceID, rateSeconds: Int) async throws -> SamplingRateResult
}

// MARK: Diagnostics repository

public protocol DiagnosticsRepository: Sendable {
    func bridgeStatus() async throws -> BridgeStatus
}
