// MARK: Device payloads

struct MetricDTO: Decodable {
    let kind: String
    let value: Double
    let unit: String
}

struct DeviceDTO: Decodable {
    let id: String
    let name: String
    let kind: String
    let connection: String
    let batteryPercent: Int?
    let signalDbm: Int
    let samplingRateSeconds: Int
    let isPoweredOn: Bool
    let targetTemperature: Double?
    let metrics: [MetricDTO]
}

struct DeviceListData: Decodable { let devices: [DeviceDTO] }
struct DeviceData: Decodable { let device: DeviceDTO }
struct SamplingRateData: Decodable {
    let deviceId: String
    let appliedRateSeconds: Int
}
// MARK: Diagnostics payload

struct StatusData: Decodable {
    let status: String
    let messageCount: Int
}
