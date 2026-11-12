enum AppStrings {
    enum DeviceList {
        static let title = "Gateway & Devices"
        static let opening = "Opening device"
        static let empty = "No devices found"
        static let loadFailed = "Couldn't load devices"
        static let retry = "Retry"
        static let hvac = "HVAC"
        static let temperatureHumidity = "Temp & Humidity"
        static let airQuality = "Air Quality"
        static let gateway = "Gateway"
        static func battery(_ percent: Int) -> String { "Battery \(percent)%" }
    }

    enum DeviceDetail {
        static let status = "Status"
        static let connection = "Connection"
        static let online = "Online"
        static let offline = "Offline"
        static let battery = "Battery"
        static let signal = "Signal"
        static let telemetry = "Telemetry"
        static let power = "Power"
        static let targetTemperature = "Target temperature"
        static let samplingRate = "Sampling rate"
        static let applySamplingRate = "Apply sampling rate"
        static let controls = "Controls"
        static let diagnostics = "Bridge diagnostics"
        static let temperature = "Temperature"
        static let humidity = "Humidity"
        static let powerConsumption = "Power consumption"
        static func batteryPercent(_ value: Int) -> String { "\(value)%" }
        static func signalValue(_ value: Int) -> String { "\(value) dBm" }
    }

    enum Diagnostics {
        static let title = "Bridge Diagnostics"
        static let checking = "Checking bridge…"
        static let ready = "Bridge ready"
        static let notReady = "Bridge not ready"
        static let unavailable = "Bridge unavailable"
        static func messageCount(_ count: Int) -> String { "Messages handled: \(count)" }
    }

    enum Common {
        static let mainsPowered = "Mains powered"
    }
}
