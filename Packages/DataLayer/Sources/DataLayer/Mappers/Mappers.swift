import Domain

// MARK: Device mapping

enum DeviceMapper {
    static func toDomain(_ dto: DeviceDTO) throws -> Device {
        guard
            let kind = DeviceKind(rawValue: dto.kind),
            let connection = ConnectionStatus(rawValue: dto.connection)
        else {
            throw DomainError.unknown
        }

        let metrics = try dto.metrics.map { metric -> Metric in
            guard let metricKind = MetricKind(rawValue: metric.kind) else {
                throw DomainError.unknown
            }
            return Metric(kind: metricKind, value: metric.value, unit: metric.unit)
        }

        return Device(
            id: dto.id,
            name: dto.name,
            kind: kind,
            connection: connection,
            batteryPercent: dto.batteryPercent,
            signalDbm: dto.signalDbm,
            samplingRateSeconds: dto.samplingRateSeconds,
            isPoweredOn: dto.isPoweredOn,
            targetTemperature: dto.targetTemperature,
            metrics: metrics
        )
    }
}

// MARK: Command mapping

enum CommandMapper {
    static func toWire(_ command: DeviceCommand) -> (name: String, value: CommandValue) {
        switch command {
        case .setPower(let isOn): return ("setPower", .bool(isOn))
        case .setTargetTemperature(let value): return ("setTargetTemperature", .number(value))
        }
    }
}
