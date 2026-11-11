//
//  DiagnosticsViewController.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

import Domain
import UIKit

final class DiagnosticsViewController: UIViewController {

    // MARK: Variables

    private let viewModel: DiagnosticsViewModel
    private let embedded: UIViewController
    private let headerView = UIView()
    private let statusLabel = UILabel()
    private let detailLabel = UILabel()
    private let flutterContainer = UIView()

    // MARK: Initializer

    init(viewModel: DiagnosticsViewModel, embedding embedded: UIViewController) {
        self.viewModel = viewModel
        self.embedded = embedded
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        title = AppStrings.Diagnostics.title
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            primaryAction: UIAction { [weak self] _ in self?.ping() }
        )

        layoutHeader()
        embedFlutter()

        IoTGatewayApp.observe { [weak self] in
            guard let self else { return }
            render(viewModel.state)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ping()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil { removeFlutter() }
    }

    private func ping() {
        Task { [weak self] in await self?.viewModel.ping() }
    }

    // MARK: Layout

    private func layoutHeader() {
        headerView.backgroundColor = .secondarySystemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .preferredFont(forTextStyle: .headline)
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [statusLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(stack)

        flutterContainer.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerView)
        view.addSubview(flutterContainer)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stack.topAnchor.constraint(
                equalTo: headerView.topAnchor,
                constant: 12
            ),
            stack.bottomAnchor.constraint(
                equalTo: headerView.bottomAnchor,
                constant: -12
            ),
            stack.leadingAnchor.constraint(
                equalTo: headerView.leadingAnchor,
                constant: 16
            ),
            stack.trailingAnchor.constraint(
                equalTo: headerView.trailingAnchor,
                constant: -16
            ),

            flutterContainer.topAnchor.constraint(
                equalTo: headerView.bottomAnchor
            ),
            flutterContainer.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            flutterContainer.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            flutterContainer.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
    }

    // MARK: Child view controller

    private func embedFlutter() {
        addChild(embedded)
        embedded.view.translatesAutoresizingMaskIntoConstraints = false
        flutterContainer.addSubview(embedded.view)
        NSLayoutConstraint.activate([
            embedded.view.topAnchor.constraint(
                equalTo: flutterContainer.topAnchor
            ),
            embedded.view.bottomAnchor.constraint(
                equalTo: flutterContainer.bottomAnchor
            ),
            embedded.view.leadingAnchor.constraint(
                equalTo: flutterContainer.leadingAnchor
            ),
            embedded.view.trailingAnchor.constraint(
                equalTo: flutterContainer.trailingAnchor
            )
        ])
        embedded.didMove(toParent: self)
    }

    private func removeFlutter() {
        embedded.willMove(toParent: nil)
        embedded.view.removeFromSuperview()
        embedded.removeFromParent()
    }

    // MARK: Rendering

    private func render(_ state: ViewState<DiagnosticsViewModel.Reading>) {
        switch state {
        case .idle, .loading:
            statusLabel.text = AppStrings.Diagnostics.checking
            detailLabel.text = nil

        case .loaded(let reading):
            statusLabel.text =
                reading.status.isReady ? AppStrings.Diagnostics.ready : AppStrings.Diagnostics.notReady
            statusLabel.textColor =
                reading.status.isReady ? .systemGreen : .systemOrange
            detailLabel.text =
                AppStrings.Diagnostics.messageCount(reading.status.messageCount)

        case .failed(let message):
            statusLabel.text = AppStrings.Diagnostics.unavailable
            statusLabel.textColor = .systemRed
            detailLabel.text = message
        }
    }
}
