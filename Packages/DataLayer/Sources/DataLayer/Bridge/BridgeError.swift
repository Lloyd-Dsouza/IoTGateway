public enum BridgeError: Error, Equatable, Sendable {
    case remote(code: String, message: String?)
    case notImplemented
    case timeout
    case notReady
    case malformedResponse
}
