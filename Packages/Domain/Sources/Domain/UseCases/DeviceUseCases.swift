// MARK: Fetch devices

public struct FetchDevicesUseCase: Sendable {
    private let repository: any DeviceRepository
    public init(repository: any DeviceRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Device] {
        try await repository.fetchDevices()
    }
}

// MARK: Get device

public struct GetDeviceUseCase: Sendable {
    private let repository: any DeviceRepository
    public init(repository: any DeviceRepository) {
        self.repository = repository
    }

    public func execute(deviceId: DeviceID) async throws -> Device {
        try await repository.device(id: deviceId)
    }
}

// MARK: Send device command

public struct SendDeviceCommandUseCase: Sendable {
    private let repository: any DeviceRepository
    public init(repository: any DeviceRepository) {
        self.repository = repository
    }

    public func execute(_ command: DeviceCommand, deviceId: DeviceID) async throws -> Device {
        let device = try await repository.device(id: deviceId)

        guard device.isOnline else { throw DomainError.deviceOffline }

        switch command {
        case .setPower:
            guard device.kind == .hvac else {
                throw DomainError.invalidValue(DomainMessages.powerRequiresHVAC)
            }
        case .setTargetTemperature(let value):
            guard device.kind == .hvac else {
                throw DomainError.invalidValue(DomainMessages.temperatureRequiresHVAC)
            }
            guard DeviceLimits.targetTemperature.contains(value) else {
                throw DomainError.invalidValue(DomainMessages.temperatureRange)
            }
        }

        return try await repository.send(command, to: deviceId)
    }
}
