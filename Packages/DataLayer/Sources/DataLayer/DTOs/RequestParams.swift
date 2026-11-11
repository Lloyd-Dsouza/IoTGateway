struct DeviceIdParams: Encodable {
    let deviceId: String
}

struct SamplingRateParams: Encodable {
    let deviceId: String
    let rateSeconds: Int
}

struct CommandParams: Encodable {
    let deviceId: String
    let command: String
    let value: CommandValue
}

enum CommandValue: Encodable {
    case bool(Bool)
    case number(Double)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        }
    }
}
