//
//  AppCoordinator.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

import Domain
import UIKit

@MainActor
final class AppCoordinator {
    // MARK: Variables

    private let navigationController: UINavigationController
    private let screenFactory: ScreenFactory

    // MARK: Initializer

    init(
        navigationController: UINavigationController,
        screenFactory: ScreenFactory
    ) {
        self.navigationController = navigationController
        self.screenFactory = screenFactory
    }

    // MARK: Navigation

    func start() {
        let viewController = screenFactory.makeDeviceList { [weak self] device in
            self?.showDetail(for: device)
        }
        navigationController.setViewControllers(
            [viewController],
            animated: false
        )
    }

    private func showDetail(for device: Device) {
        let viewController = screenFactory.makeDeviceDetail(device: device) { [weak self] in
            self?.showDiagnostics()
        }
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showDiagnostics() {
        let viewController = screenFactory.makeDiagnostics()
        navigationController.pushViewController(viewController, animated: true)
    }
}
