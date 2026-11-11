public enum DomainError: Error, Equatable, Sendable {
    case deviceOffline
    case notFound
    case invalidValue(String)
    case timeout
    case transportUnavailable
    case unknown

    public var userMessage: String {
        switch self {
        case .deviceOffline:
            return DomainMessages.deviceOffline
        case .notFound:
            return DomainMessages.notFound
        case .invalidValue(let reason):
            return reason
        case .timeout:
            return DomainMessages.timeout
        case .transportUnavailable:
            return DomainMessages.transportUnavailable
        case .unknown:
            return DomainMessages.unknown
        }
    }
}
