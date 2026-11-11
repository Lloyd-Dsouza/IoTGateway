import Domain

public struct DeviceRepositoryImpl: DeviceRepository {
    private let client: BridgeClient

    public init(transport: any IoTTransport) {
        self.client = BridgeClient(transport: transport)
    }

    public func fetchDevices() async throws -> [Device] {
        let payload = try await client.call("devices.list", params: EmptyParams(), as: DeviceListData.self)
        return try payload.devices.map(DeviceMapper.toDomain)
    }

    public func device(id: DeviceID) async throws -> Device {
        let payload = try await client.call("device.get", params: DeviceIdParams(deviceId: id), as: DeviceData.self)
        return try DeviceMapper.toDomain(payload.device)
    }

    public func send(_ command: DeviceCommand, to deviceId: DeviceID) async throws -> Device {
        let wire = CommandMapper.toWire(command)
        let params = CommandParams(deviceId: deviceId, command: wire.name, value: wire.value)
        let payload = try await client.call("device.sendCommand", params: params, as: DeviceData.self)
        return try DeviceMapper.toDomain(payload.device)
    }

    public func updateSamplingRate(deviceId: DeviceID, rateSeconds: Int) async throws -> SamplingRateResult {
        let params = SamplingRateParams(deviceId: deviceId, rateSeconds: rateSeconds)
        let payload = try await client.call("device.setSamplingRate", params: params, as: SamplingRateData.self)
        return SamplingRateResult(deviceId: payload.deviceId, appliedRateSeconds: payload.appliedRateSeconds)
    }
}
