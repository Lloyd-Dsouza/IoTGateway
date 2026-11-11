enum DomainMessages {
    static let deviceOffline = "This device is offline."
    static let notFound = "Device not found."
    static let timeout = "The request timed out. Please try again."
    static let transportUnavailable = "Can't reach the device service."
    static let unknown = "Something went wrong."
    static let powerRequiresHVAC = "Only HVAC units can be switched on or off."
    static let temperatureRequiresHVAC = "Only HVAC units have a target temperature."
    static let temperatureRange = "Target temperature must be between 16 and 30 °C."
    static let samplingRateRange = "Sampling rate must be between 1 and 60 seconds."
}
