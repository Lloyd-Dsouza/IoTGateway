// MARK: Public enums for Device and Metrics

public typealias DeviceID = String

public enum DeviceKind: String, Sendable, Equatable {
    case hvac, tempHumidity, gateway, airQuality
}

public enum ConnectionStatus: String, Sendable, Equatable {
    case online, offline
}

public enum MetricKind: String, Sendable, Equatable {
    case temperature, humidity, powerConsumption
}

public enum DeviceCommand: Sendable, Equatable {
    case setPower(Bool)
    case setTargetTemperature(Double)
}

// MARK: Public structs for Device and Metrics

public struct Metric: Sendable, Equatable {
    public let kind: MetricKind
    public let value: Double
    public let unit: String

    public init(kind: MetricKind, value: Double, unit: String) {
        self.kind = kind
        self.value = value
        self.unit = unit
    }
}

public struct Device: Identifiable, Sendable, Equatable {
    public let id: DeviceID
    public let name: String
    public let kind: DeviceKind
    public let connection: ConnectionStatus
    public let batteryPercent: Int?
    public let signalDbm: Int
    public let samplingRateSeconds: Int
    public let isPoweredOn: Bool
    public let targetTemperature: Double?
    public let metrics: [Metric]

    public init(
        id: DeviceID, name: String, kind: DeviceKind, connection: ConnectionStatus,
        batteryPercent: Int?, signalDbm: Int, samplingRateSeconds: Int,
        isPoweredOn: Bool, targetTemperature: Double?, metrics: [Metric]
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.connection = connection
        self.batteryPercent = batteryPercent
        self.signalDbm = signalDbm
        self.samplingRateSeconds = samplingRateSeconds
        self.isPoweredOn = isPoweredOn
        self.targetTemperature = targetTemperature
        self.metrics = metrics
    }

    public var isOnline: Bool { connection == .online }

    public var signalBars: Int {
        switch signalDbm {
        case (-55)...: return 4
        case (-67)...: return 3
        case (-80)...: return 2
        case (-90)...: return 1
        default: return 0
        }
    }
}

public struct SamplingRateResult: Sendable, Equatable {
    public let deviceId: DeviceID
    public let appliedRateSeconds: Int

    public init(deviceId: DeviceID, appliedRateSeconds: Int) {
        self.deviceId = deviceId
        self.appliedRateSeconds = appliedRateSeconds
    }
}

public struct BridgeStatus: Sendable, Equatable {
    public let isReady: Bool
    public let messageCount: Int

    public init(isReady: Bool, messageCount: Int) {
        self.isReady = isReady
        self.messageCount = messageCount
    }
}
