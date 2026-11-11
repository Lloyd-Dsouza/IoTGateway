import Domain
import XCTest

// A fake kitchen: records calls and returns canned data. No Flutter involved.
final class MockDeviceRepository: DeviceRepository, @unchecked Sendable {
    var devices: [Device] = []
    var sendCallCount = 0
    var updateCallCount = 0

    func fetchDevices() async throws -> [Device] { devices }

    func device(id: DeviceID) async throws -> Device {
        guard let device = devices.first(where: { $0.id == id }) else { throw DomainError.notFound }
        return device
    }

    func send(_ command: DeviceCommand, to deviceId: DeviceID) async throws -> Device {
        sendCallCount += 1
        return try await device(id: deviceId)
    }

    func updateSamplingRate(deviceId: DeviceID, rateSeconds: Int) async throws -> SamplingRateResult {
        updateCallCount += 1
        return SamplingRateResult(deviceId: deviceId, appliedRateSeconds: rateSeconds)
    }
}

private func makeDevice(
    id: String = "XYZ1001",
    kind: DeviceKind = .hvac,
    connection: ConnectionStatus = .online
) -> Device {
    Device(
        id: id, name: "Test Device", kind: kind, connection: connection,
        batteryPercent: nil, signalDbm: -60, samplingRateSeconds: 10,
        isPoweredOn: true, targetTemperature: 22, metrics: [])
}

final class UpdateSamplingRateUseCaseTests: XCTestCase {
    func testRateOutOfRangeIsRejectedAndRepositoryIsNotCalled() async {
        let repo = MockDeviceRepository()
        let sut = UpdateSamplingRateUseCase(repository: repo)

        do {
            _ = try await sut.execute(deviceId: "XYZ1001", rate: 500)
            XCTFail("Expected an error")
        } catch DomainError.invalidValue {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(repo.updateCallCount, 0)
    }

    func testValidRateIsPassedToRepository() async throws {
        let repo = MockDeviceRepository()
        let sut = UpdateSamplingRateUseCase(repository: repo)

        let result = try await sut.execute(deviceId: "XYZ1001", rate: 5)

        XCTAssertEqual(result, SamplingRateResult(deviceId: "XYZ1001", appliedRateSeconds: 5))
        XCTAssertEqual(repo.updateCallCount, 1)
    }
}

final class SendDeviceCommandUseCaseTests: XCTestCase {
    func testCommandToOfflineDeviceIsRejected() async {
        let repo = MockDeviceRepository()
        repo.devices = [makeDevice(connection: .offline)]
        let sut = SendDeviceCommandUseCase(repository: repo)

        do {
            _ = try await sut.execute(.setPower(true), deviceId: "XYZ1001")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? DomainError, .deviceOffline)
        }
        XCTAssertEqual(repo.sendCallCount, 0)
    }

    func testTargetTemperatureOutOfRangeIsRejected() async {
        let repo = MockDeviceRepository()
        repo.devices = [makeDevice()]
        let sut = SendDeviceCommandUseCase(repository: repo)

        do {
            _ = try await sut.execute(.setTargetTemperature(45), deviceId: "XYZ1001")
            XCTFail("Expected an error")
        } catch DomainError.invalidValue {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(repo.sendCallCount, 0)
    }

    func testTargetTemperatureOnNonHVACIsRejected() async {
        let repo = MockDeviceRepository()
        repo.devices = [makeDevice(id: "XYZ1002", kind: .tempHumidity)]
        let sut = SendDeviceCommandUseCase(repository: repo)

        do {
            _ = try await sut.execute(.setTargetTemperature(22), deviceId: "XYZ1002")
            XCTFail("Expected an error")
        } catch DomainError.invalidValue {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testValidCommandIsSent() async throws {
        let repo = MockDeviceRepository()
        repo.devices = [makeDevice()]
        let sut = SendDeviceCommandUseCase(repository: repo)

        _ = try await sut.execute(.setTargetTemperature(22), deviceId: "XYZ1001")

        XCTAssertEqual(repo.sendCallCount, 1)
    }
}

final class DeviceTests: XCTestCase {
    func testSignalBarsMapping() {
        func bars(_ dbm: Int) -> Int {
            Device(
                id: "a", name: "a", kind: .gateway, connection: .online, batteryPercent: nil,
                signalDbm: dbm, samplingRateSeconds: 10, isPoweredOn: true,
                targetTemperature: nil, metrics: []
            ).signalBars
        }
        XCTAssertEqual(bars(-50), 4)
        XCTAssertEqual(bars(-70), 2)
        XCTAssertEqual(bars(-95), 0)
    }
}
