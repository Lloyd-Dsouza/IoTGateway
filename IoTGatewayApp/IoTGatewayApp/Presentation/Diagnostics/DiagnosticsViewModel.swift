//
//  DiagnosticsViewModel.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

import Domain
import Observation

@MainActor
@Observable
final class DiagnosticsViewModel {
    // MARK: Types

    struct Reading {
        let status: BridgeStatus
    }

    // MARK: Variables

    private(set) var state: ViewState<Reading> = .idle

    @ObservationIgnored private let fetchStatus: FetchBridgeStatusUseCase

    // MARK: Initializer

    init(fetchStatus: FetchBridgeStatusUseCase) {
        self.fetchStatus = fetchStatus
    }

    // MARK: Methods

    func ping() async {
        if case .idle = state { state = .loading }

        do {
            let status = try await fetchStatus.execute()
            state = .loaded(Reading(status: status))
        } catch let error as DomainError {
            state = .failed(error.userMessage)
        } catch {
            state = .failed(DomainError.unknown.userMessage)
        }
    }
}
