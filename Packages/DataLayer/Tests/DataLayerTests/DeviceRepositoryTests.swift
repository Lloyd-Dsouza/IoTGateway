import Domain
import XCTest

@testable import DataLayer

private func deviceJSON(
    id: String = "XYZ1001",
    kind: String = "hvac",
    connection: String = "online"
) -> [String: Any] {
    [
        "id": id, "name": "Test Device", "kind": kind, "connection": connection,
        "batteryPercent": NSNull(), "signalDbm": -52, "samplingRateSeconds": 10,
        "isPoweredOn": true, "targetTemperature": 22.0,
        "metrics": [["kind": "temperature", "value": 23.4, "unit": "°C"]]
    ]
}

final class DeviceRepositoryTests: XCTestCase {

    func testFetchDevicesMapsPayloadToEntities() async throws {
        let transport = MockTransport { _, _ in
            ["devices": [deviceJSON(), deviceJSON(id: "XYZ1003", kind: "tempHumidity", connection: "offline")]]
        }
        let sut = DeviceRepositoryImpl(transport: transport)

        let devices = try await sut.fetchDevices()

        XCTAssertEqual(transport.lastMethod, "devices.list")
        XCTAssertEqual(devices.count, 2)
        XCTAssertEqual(devices[0].kind, .hvac)
        XCTAssertNil(devices[0].batteryPercent)
        XCTAssertEqual(devices[0].metrics.first, Metric(kind: .temperature, value: 23.4, unit: "°C"))
        XCTAssertEqual(devices[1].connection, .offline)
    }

    func testUpdateSamplingRateSendsExpectedPayloadAndMapsResult() async throws {
        let transport = MockTransport { _, _ in ["deviceId": "XYZ1001", "appliedRateSeconds": 5] }
        let sut = DeviceRepositoryImpl(transport: transport)

        let result = try await sut.updateSamplingRate(deviceId: "XYZ1001", rateSeconds: 5)

        XCTAssertEqual(transport.lastMethod, "device.setSamplingRate")
        XCTAssertEqual(transport.lastParams["deviceId"] as? String, "XYZ1001")
        XCTAssertEqual(transport.lastParams["rateSeconds"] as? Int, 5)
        XCTAssertEqual(result, SamplingRateResult(deviceId: "XYZ1001", appliedRateSeconds: 5))
    }

    func testSendCommandEncodesCommandNameAndValue() async throws {
        let transport = MockTransport { _, _ in ["device": deviceJSON()] }
        let sut = DeviceRepositoryImpl(transport: transport)

        _ = try await sut.send(.setPower(false), to: "XYZ1001")

        XCTAssertEqual(transport.lastMethod, "device.sendCommand")
        XCTAssertEqual(transport.lastParams["command"] as? String, "setPower")
        XCTAssertEqual(transport.lastParams["value"] as? Bool, false)
    }

    func testRemoteOfflineErrorBecomesDeviceOffline() async {
        let transport = MockTransport { _, _ in
            throw BridgeError.remote(code: "DEVICE_OFFLINE", message: "Device XYZ1003 is offline.")
        }
        let sut = DeviceRepositoryImpl(transport: transport)

        do {
            _ = try await sut.updateSamplingRate(deviceId: "XYZ1003", rateSeconds: 5)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? DomainError, .deviceOffline)
        }
    }

    func testTransportTimeoutBecomesDomainTimeout() async {
        let transport = MockTransport { _, _ in throw BridgeError.timeout }
        let sut = DeviceRepositoryImpl(transport: transport)

        do {
            _ = try await sut.fetchDevices()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? DomainError, .timeout)
        }
    }

    func testUnknownEnumValueBecomesUnknownError() async {
        let transport = MockTransport { _, _ in ["devices": [deviceJSON(kind: "toaster")]] }
        let sut = DeviceRepositoryImpl(transport: transport)

        do {
            _ = try await sut.fetchDevices()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? DomainError, .unknown)
        }
    }
}
