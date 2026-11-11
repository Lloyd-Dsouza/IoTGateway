//
//  DeviceListViewController.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

import Domain
import UIKit

final class DeviceListViewController: UIViewController {

    // MARK: Variables

    var onSelectDevice: ((Device) -> Void)?

    private let viewModel: DeviceListViewModel
    private var devicesByID: [DeviceID: Device] = [:]
    private var dataSource: UICollectionViewDiffableDataSource<Int, DeviceID>!
    private var openingDeviceID: DeviceID?

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewCompositionalLayout.list(
            using: UICollectionLayoutListConfiguration(
                appearance: .insetGrouped
            )
        )
    )

    // MARK: Initializer

    init(viewModel: DeviceListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = AppStrings.DeviceList.title
        view.backgroundColor = .systemBackground

        configureCollectionView()
        configureDataSource()

        IoTGatewayApp.observe { [weak self] in
            guard let self else { return }
            render(viewModel.state)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let id = openingDeviceID {
            openingDeviceID = nil
            collectionView.isUserInteractionEnabled = true
            reconfigureDevice(id)
        }
        reload()
    }

    private func reload() {
        Task { [weak self] in await self?.viewModel.load() }
    }

    // MARK: Setup

    private func configureCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            )
        ])

        let refresh = UIRefreshControl()
        refresh.addAction(
            UIAction { [weak self] _ in
                Task { [weak self] in
                    await self?.viewModel.load()
                    self?.collectionView.refreshControl?.endRefreshing()
                }
            },
            for: .valueChanged
        )
        collectionView.refreshControl = refresh
    }

    private func configureDataSource() {
        typealias DeviceCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, DeviceID>
        let registration = DeviceCellRegistration { [weak self] cell, _, id in
            guard let self, let device = devicesByID[id] else { return }

            var content = cell.defaultContentConfiguration()
            content.text = device.name
            content.secondaryText =
                "\(device.kind.title) · \(device.batteryText)"
            content.image = UIImage(systemName: "circle.fill")
            content.imageProperties.tintColor =
                device.isOnline ? .systemGreen : .systemRed
            content.imageProperties.maximumSize = CGSize(width: 12, height: 12)
            if !device.isOnline {
                content.textProperties.color = .secondaryLabel
            }
            cell.contentConfiguration = content

            cell.accessories = [
                .customView(
                    configuration: .init(
                        customView: accessory(for: device),
                        placement: .trailing()
                    )
                )
            ]
        }

        dataSource = UICollectionViewDiffableDataSource<Int, DeviceID>(
            collectionView: collectionView
        ) { collectionView, indexPath, id in
            collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: id
            )
        }
    }

    private func accessory(for device: Device) -> UIView {
        if openingDeviceID == device.id {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.accessibilityLabel = AppStrings.DeviceList.opening
            spinner.startAnimating()
            return spinner
        }
        let signal = UIImageView(
            image: UIImage(systemName: "cellularbars", variableValue: Double(device.signalBars) / 4)
        )
        signal.tintColor = device.isOnline ? .label : .tertiaryLabel
        return signal
    }

    // MARK: Rendering

    private func render(_ state: ViewState<[Device]>) {
        switch state {
        case .idle:
            contentUnavailableConfiguration = nil

        case .loading:
            if devicesByID.isEmpty {
                contentUnavailableConfiguration =
                    UIContentUnavailableConfiguration.loading()
            }

        case .loaded(let devices):
            apply(devices)
            if devices.isEmpty {
                var empty = UIContentUnavailableConfiguration.empty()
                empty.image = UIImage(systemName: "sensor")
                empty.text = AppStrings.DeviceList.empty
                contentUnavailableConfiguration = empty
            } else {
                contentUnavailableConfiguration = nil
            }

        case .failed(let message):
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "exclamationmark.triangle")
            config.text = AppStrings.DeviceList.loadFailed
            config.secondaryText = message
            var retry = UIButton.Configuration.filled()
            retry.title = AppStrings.DeviceList.retry
            config.button = retry
            config.buttonProperties.primaryAction = UIAction { [weak self] _ in
                self?.reload()
            }
            contentUnavailableConfiguration = config
        }
    }

    private func apply(_ devices: [Device]) {
        devicesByID = Dictionary(
            uniqueKeysWithValues: devices.map { ($0.id, $0) }
        )

        var snapshot = NSDiffableDataSourceSnapshot<Int, DeviceID>()
        snapshot.appendSections([0])
        snapshot.appendItems(devices.map(\.id))
        snapshot.reconfigureItems(devices.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func reconfigureDevice(_ id: DeviceID) {
        var snapshot = dataSource.snapshot()
        guard snapshot.indexOfItem(id) != nil else { return }
        snapshot.reconfigureItems([id])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Selection

extension DeviceListViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard openingDeviceID == nil,
            let id = dataSource.itemIdentifier(for: indexPath),
            let device = devicesByID[id],
            let onSelectDevice
        else { return }

        openingDeviceID = id
        collectionView.isUserInteractionEnabled = false
        reconfigureDevice(id)

        // Let the spinner appear before creating the detail screen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self, self.openingDeviceID == id else { return }
            onSelectDevice(device)
        }
    }
}

// MARK: Display text

extension DeviceKind {
    fileprivate var title: String {
        switch self {
        case .hvac: AppStrings.DeviceList.hvac
        case .tempHumidity: AppStrings.DeviceList.temperatureHumidity
        case .gateway: AppStrings.DeviceList.gateway
        }
    }
}

extension Device {
    fileprivate var batteryText: String {
        if let battery = batteryPercent {
            AppStrings.DeviceList.battery(battery)
        } else {
            AppStrings.Common.mainsPowered
        }
    }
}
