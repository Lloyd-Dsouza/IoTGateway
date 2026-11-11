//
//  DeviceDetailView.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

import Domain
import SwiftUI

struct DeviceDetailView: View {
    // MARK: Variables

    @Bindable var viewModel: DeviceDetailViewModel
    let onShowDiagnostics: () -> Void

    // MARK: View

    var body: some View {
        let device = viewModel.device
        let targetTemperature = AppStrings.DeviceDetail.targetTemperature

        List {
            Section(AppStrings.DeviceDetail.status) {
                LabeledContent(
                    AppStrings.DeviceDetail.connection,
                    value: device.isOnline ? AppStrings.DeviceDetail.online : AppStrings.DeviceDetail.offline
                )
                LabeledContent(
                    AppStrings.DeviceDetail.battery,
                    value: device.batteryPercent.map(AppStrings.DeviceDetail.batteryPercent)
                        ?? AppStrings.Common.mainsPowered
                )
                LabeledContent(
                    AppStrings.DeviceDetail.signal,
                    value: AppStrings.DeviceDetail.signalValue(device.signalDbm)
                )
            }

            Section(AppStrings.DeviceDetail.telemetry) {
                ForEach(device.metrics, id: \.kind) { metric in
                    LabeledContent(
                        metric.kind.title,
                        value: metric.displayValue
                    )
                }
            }

            Section {
                if device.kind == .hvac {
                    Toggle(
                        AppStrings.DeviceDetail.power,
                        isOn: Binding(
                            get: { device.isPoweredOn },
                            set: { viewModel.setPower($0) }
                        )
                    )
                    .disabled(viewModel.isBusy)

                    VStack(alignment: .leading) {
                        Text(
                            "\(targetTemperature): \(viewModel.targetDraft, specifier: "%.1f") °C"
                        )
                        Slider(
                            value: $viewModel.targetDraft,
                            in: DeviceLimits.targetTemperature,
                            step: 0.5,
                            onEditingChanged: { editing in
                                if !editing { viewModel.commitTarget() }  // send when the finger lifts
                            }
                        )
                        .disabled(viewModel.isBusy)
                    }
                }

                Stepper(
                    value: $viewModel.rateDraft,
                    in: DeviceLimits.samplingRateSeconds
                ) {
                    Text("\(AppStrings.DeviceDetail.samplingRate): \(viewModel.rateDraft) s")
                }
                Button(AppStrings.DeviceDetail.applySamplingRate) { viewModel.applySamplingRate() }
                    .disabled(
                        viewModel.isBusy
                            || viewModel.rateDraft == device.samplingRateSeconds
                    )
            } header: {
                HStack {
                    Text(AppStrings.DeviceDetail.controls)
                    if viewModel.isBusy { ProgressView() }
                }
            }

            Button {
                onShowDiagnostics()
            } label: {
                Label(
                    AppStrings.DeviceDetail.diagnostics,
                    systemImage: "waveform.path.ecg"
                )
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let message = viewModel.bannerMessage {
                ErrorBanner(
                    message: message,
                    onDismiss: viewModel.dismissBanner
                )
            }
        }
        .task { await viewModel.pollWhileVisible() }
    }
}

private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.footnote)
            Spacer()
            Button(action: onDismiss) { Image(systemName: "xmark") }
        }
        .padding(12)
        .background(Color.red.opacity(0.15))
    }
}

// MARK: - Display text (presentation concerns)

extension MetricKind {
    fileprivate var title: String {
        switch self {
        case .temperature: AppStrings.DeviceDetail.temperature
        case .humidity: AppStrings.DeviceDetail.humidity
        case .powerConsumption: AppStrings.DeviceDetail.powerConsumption
        }
    }
}

extension Metric {
    fileprivate var displayValue: String {
        "\(value.formatted(.number.precision(.fractionLength(1)))) \(unit)"
    }
}
