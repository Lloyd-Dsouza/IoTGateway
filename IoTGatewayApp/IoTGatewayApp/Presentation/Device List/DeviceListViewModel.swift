//
//  DeviceListViewModel.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

import Domain
import Observation

@MainActor
@Observable
final class DeviceListViewModel {
    // MARK: Variables

    private(set) var state: ViewState<[Device]> = .idle

    @ObservationIgnored private let fetchDevices: FetchDevicesUseCase

    // MARK: Initializer

    init(fetchDevices: FetchDevicesUseCase) {
        self.fetchDevices = fetchDevices
    }

    // MARK: Methods

    func load() async {
        if case .loaded = state {} else { state = .loading }
        do {
            state = .loaded(try await fetchDevices.execute())
        } catch let error as DomainError {
            state = .failed(error.userMessage)
        } catch {
            state = .failed(DomainError.unknown.userMessage)
        }
    }
}
