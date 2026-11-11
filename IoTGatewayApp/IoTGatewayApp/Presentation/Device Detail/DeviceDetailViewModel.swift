//
//  DeviceDetailViewModel.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

import Domain
import Observation

@MainActor
@Observable
final class DeviceDetailViewModel {
    // MARK: Variables

    private(set) var device: Device
    private(set) var bannerMessage: String?
    private(set) var isBusy = false

    var targetDraft: Double
    var rateDraft: Int

    @ObservationIgnored private let getDevice: GetDeviceUseCase
    @ObservationIgnored private let sendCommand: SendDeviceCommandUseCase
    @ObservationIgnored private let updateSamplingRate: UpdateSamplingRateUseCase
    @ObservationIgnored private let pollInterval: Duration
    @ObservationIgnored private var bannerFromPolling = false

    // MARK: Initializer

    init(
        device: Device,
        getDevice: GetDeviceUseCase,
        sendCommand: SendDeviceCommandUseCase,
        updateSamplingRate: UpdateSamplingRateUseCase,
        pollInterval: Duration = .seconds(3)
    ) {
        self.device = device
        self.targetDraft = device.targetTemperature ?? 22
        self.rateDraft = device.samplingRateSeconds
        self.getDevice = getDevice
        self.sendCommand = sendCommand
        self.updateSamplingRate = updateSamplingRate
        self.pollInterval = pollInterval
    }

    // MARK: Telemetry polling

    func pollWhileVisible() async {
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: pollInterval)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    func refresh() async {
        do {
            device = try await getDevice.execute(deviceId: device.id)
            if bannerFromPolling { bannerMessage = nil }
        } catch is CancellationError {
            return
        } catch {
            bannerMessage = Self.message(for: error)
            bannerFromPolling = true
        }
    }

    // MARK: Controls

    func setPower(_ isOn: Bool) {
        perform { [self] in
            device = try await sendCommand.execute(
                .setPower(isOn),
                deviceId: device.id
            )
            syncDrafts()
        }
    }

    func commitTarget() {
        perform { [self] in
            device = try await sendCommand.execute(
                .setTargetTemperature(targetDraft),
                deviceId: device.id
            )
            syncDrafts()
        }
    }

    func applySamplingRate() {
        perform { [self] in
            let result = try await updateSamplingRate.execute(
                deviceId: device.id,
                rate: rateDraft
            )
            rateDraft = result.appliedRateSeconds
            device = try await getDevice.execute(deviceId: device.id)
        }
    }

    func dismissBanner() { bannerMessage = nil }

    // MARK: Helpers

    private func perform(_ work: @escaping @MainActor () async throws -> Void) {
        guard !isBusy else { return }
        isBusy = true
        Task {
            do {
                try await work()
                bannerMessage = nil
            } catch {
                bannerMessage = Self.message(for: error)
                syncDrafts()
            }
            bannerFromPolling = false
            isBusy = false
        }
    }

    private func syncDrafts() {
        targetDraft = device.targetTemperature ?? targetDraft
        rateDraft = device.samplingRateSeconds
    }

    private static func message(for error: Error) -> String {
        (error as? DomainError)?.userMessage ?? DomainError.unknown.userMessage
    }
}
