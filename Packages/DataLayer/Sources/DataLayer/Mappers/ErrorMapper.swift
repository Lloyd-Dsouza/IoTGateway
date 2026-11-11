import Domain

enum ErrorMapper {
    static func toDomain(_ error: BridgeError) -> DomainError {
        switch error {
        case .remote(let code, let message):
            switch code {
            case "DEVICE_OFFLINE": return .deviceOffline
            case "DEVICE_NOT_FOUND": return .notFound
            case "INVALID_VALUE": return .invalidValue(message ?? "Invalid value.")
            case "UNKNOWN_METHOD": return .transportUnavailable
            default: return .unknown
            }
        case .notImplemented, .notReady: return .transportUnavailable
        case .timeout: return .timeout
        case .malformedResponse: return .unknown
        }
    }
}
