import DataLayer
import Flutter
import Foundation

@MainActor
final class FlutterChannelTransport: IoTTransport {
    // MARK: Variables

    private let channel: FlutterMethodChannel
    private let requestTimeout: Duration
    private let readinessTimeout: Duration
    private var isReady = false

    // MARK: Initializer

    init(
        engine: FlutterEngine,
        requestTimeout: Duration = .seconds(5),
        readinessTimeout: Duration = .seconds(5)
    ) {
        self.channel = FlutterMethodChannel(
            name: BridgeContract.channelName,
            binaryMessenger: engine.binaryMessenger
        )
        self.requestTimeout = requestTimeout
        self.readinessTimeout = readinessTimeout
    }

    // MARK: Methods

    func warmUp() async {
        try? await ensureReady()
    }

    // MARK: IoTTransport

    func send(_ request: Data) async throws -> Data {
        try await ensureReady()
        return try await invoke(request)
    }

    // MARK: Readiness

    private func ensureReady() async throws {
        if isReady { return }

        let ping = #"{"requestId":"warmup","method":"bridge.status","params":{}}"#
        let deadline = ContinuousClock.now + readinessTimeout

        // Flutter may not have registered the channel yet, so retry until it is ready.
        while true {
            do {
                _ = try await invoke(Data(ping.utf8))
                isReady = true
                return
            } catch BridgeError.notImplemented {
                if ContinuousClock.now >= deadline { throw BridgeError.notReady }
                try await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    // MARK: One round trip

    private func invoke(_ request: Data) async throws -> Data {
        guard let json = String(data: request, encoding: .utf8) else {
            throw BridgeError.malformedResponse
        }
        let timeout = requestTimeout
        let channel = self.channel

        return try await withCheckedThrowingContinuation { continuation in
            let once = OneShot(continuation)
            let timeoutTask = Task {
                do { try await Task.sleep(for: timeout) } catch { return }  // cancelled = reply arrived
                once.resume(with: .failure(BridgeError.timeout))
            }

            channel.invokeMethod(BridgeContract.methodName, arguments: json) { result in
                timeoutTask.cancel()
                once.resume(with: outcome(of: result))
            }
        }
    }
}

// MARK: - Helpers

private func outcome(of result: Any?) -> Result<Data, Error> {
    if let error = result as? FlutterError {
        return .failure(BridgeError.remote(code: error.code, message: error.message))
    }
    if FlutterMethodNotImplemented.isEqual(result) {
        return .failure(BridgeError.notImplemented)
    }
    if let string = result as? String {
        return .success(Data(string.utf8))
    }
    return .failure(BridgeError.malformedResponse)
}

private final class OneShot: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Data, Error>?

    init(_ continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<Data, Error>) {
        // The reply and timeout can arrive together. Only the first one finishes the request.
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(with: result)
    }
}
