import Domain
import Flutter
import SwiftUI
import UIKit

@MainActor
final class ScreenFactory {
    // MARK: Variables

    private let dependencies: AppDependencies

    // MARK: Initializer

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    // MARK: Screen creation

    func makeDeviceList(
        onSelectDevice: @escaping (Device) -> Void
    ) -> UIViewController {
        let viewModel = DeviceListViewModel(
            fetchDevices: dependencies.fetchDevices
        )
        let viewController = DeviceListViewController(viewModel: viewModel)
        viewController.onSelectDevice = onSelectDevice
        return viewController
    }

    func makeDeviceDetail(
        device: Device,
        onShowDiagnostics: @escaping () -> Void
    ) -> UIViewController {
        let viewModel = DeviceDetailViewModel(
            device: device,
            getDevice: dependencies.getDevice,
            sendCommand: dependencies.sendCommand,
            updateSamplingRate: dependencies.updateSamplingRate
        )
        let detailView = DeviceDetailView(
            viewModel: viewModel,
            onShowDiagnostics: onShowDiagnostics
        )
        let hosting = UIHostingController(
            rootView: detailView
        )
        hosting.title = device.name
        hosting.navigationItem.largeTitleDisplayMode = .never
        return hosting
    }

    func makeDiagnostics() -> UIViewController {
        let viewModel = DiagnosticsViewModel(
            fetchStatus: dependencies.fetchBridgeStatus
        )
        let flutterViewController = FlutterViewController(
            engine: dependencies.flutterEngine,
            nibName: nil,
            bundle: nil
        )
        return DiagnosticsViewController(
            viewModel: viewModel,
            embedding: flutterViewController
        )
    }
}
