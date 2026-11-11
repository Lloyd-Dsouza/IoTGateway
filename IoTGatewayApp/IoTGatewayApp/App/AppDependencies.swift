//
//  AppDependencies.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

import DataLayer
import Domain
import Flutter

@MainActor
final class AppDependencies {
    // MARK: Variables

    let flutterEngine: FlutterEngine
    private let transport: FlutterChannelTransport
    let fetchDevices: FetchDevicesUseCase
    let getDevice: GetDeviceUseCase
    let sendCommand: SendDeviceCommandUseCase
    let updateSamplingRate: UpdateSamplingRateUseCase
    let fetchBridgeStatus: FetchBridgeStatusUseCase

    // MARK: Initializer

    init() {
        let engine = FlutterEngine(name: "iot_engine")
        let transport = FlutterChannelTransport(engine: engine)
        let deviceRepository = DeviceRepositoryImpl(transport: transport)
        let diagnosticsRepository = DiagnosticsRepositoryImpl(transport: transport)

        self.flutterEngine = engine
        self.transport = transport
        self.fetchDevices = FetchDevicesUseCase(repository: deviceRepository)
        self.getDevice = GetDeviceUseCase(repository: deviceRepository)
        self.sendCommand = SendDeviceCommandUseCase(repository: deviceRepository)
        self.updateSamplingRate = UpdateSamplingRateUseCase(repository: deviceRepository)
        self.fetchBridgeStatus = FetchBridgeStatusUseCase(repository: diagnosticsRepository)
    }

    // MARK: Methods

    func start() {
        flutterEngine.run()
        Task { await transport.warmUp() }
    }
}
