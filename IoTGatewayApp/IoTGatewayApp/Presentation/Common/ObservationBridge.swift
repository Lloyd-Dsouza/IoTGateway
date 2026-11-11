//
//  ObservationBridge.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

import Observation

@MainActor
func observe(_ apply: @escaping @MainActor () -> Void) {
    withObservationTracking {
        apply()
    } onChange: {
        // Observation fires once, so start listening again after each change.
        Task { @MainActor in observe(apply) }
    }
}
