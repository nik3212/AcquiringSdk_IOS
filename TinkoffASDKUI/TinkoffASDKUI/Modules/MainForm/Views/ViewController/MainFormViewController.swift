//
//  MainFormViewController.swift
//  TinkoffASDKUI
//
//  Created by r.akhmadeev on 19.01.2023.
//

import UIKit
import WebKit

final class MainFormViewController: UIViewController {
    // MARK: Internal Types

    private enum Anchor: CaseIterable {
        case contentBased
        case expanded
    }

    private enum PresentationState {
        case commonSheet
        case tableView
    }

    // MARK: Dependencies

    weak var pullableContentDelegate: IPullableContainerСontentDelegate?
    private let presenter: IMainFormPresenter
    private let tableContentProvider: any IMainFormTableContentProvider
    private let keyboardService = KeyboardService()

    // MARK: Subviews

    private lazy var tableView = UITableView(frame: view.bounds)
    private lazy var commonSheetView = CommonSheetView(delegate: self)
    private lazy var hiddenWebView = WKWebView(frame: view.bounds)

    // MARK: State

    private let anchors = Anchor.allCases
    private var currentAnchor: Anchor = .contentBased
    private var presentationState: PresentationState = .commonSheet

    // MARK: Init

    init(presenter: IMainFormPresenter, tableContentProvider: any IMainFormTableContentProvider) {
        self.presenter = presenter
        self.tableContentProvider = tableContentProvider
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewsHierarchy()
        setupTableView()
        setupKeyboardObserving()
        presenter.viewDidLoad()
    }

    // MARK: Initial Configuration

    private func setupViewsHierarchy() {
        view.addSubview(hiddenWebView)
        hiddenWebView.pinEdgesToSuperview()
        hiddenWebView.isHidden = true

        view.addSubview(tableView)
        tableView.pinEdgesToSuperview()

        view.addSubview(commonSheetView)
        commonSheetView.pinEdgesToSuperview()
    }

    private func setupTableView() {
        tableView.tableHeaderView = tableContentProvider.tableHeaderView()
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.delaysContentTouches = false
        tableView.alwaysBounceVertical = false
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self

        tableContentProvider.registerCells(in: tableView)
    }

    private func setupKeyboardObserving() {
        keyboardService.onHeightDidChangeBlock = { [weak self] keyboardHeight, _ in
            guard let self = self else { return }
            self.currentAnchor = .expanded

            self.pullableContentDelegate?.updateHeight(
                animated: true,
                alongsideAnimation: nil,
                completion: { self.scrollTableFor(keyboardHeight: keyboardHeight) }
            )
        }
    }

    private func scrollTableFor(keyboardHeight: CGFloat) {
        guard keyboardHeight > .zero else {
            tableView.setContentOffset(.zero, animated: true)
            return
        }

        guard let payButtonIndex = presenter.allCells().firstIndex(where: \.isPayButton) else { return }

        let payButtonRect = tableView.rectForRow(at: IndexPath(row: payButtonIndex, section: .zero))
        let buttonsDistanceToBottom = tableView.bounds.height - payButtonRect.maxY

        let targetYOffset = buttonsDistanceToBottom > keyboardHeight
            ? .zero
            : keyboardHeight - buttonsDistanceToBottom

        tableView.setContentOffset(CGPoint(x: .zero, y: targetYOffset), animated: true)
    }
}

// MARK: - IMainFormViewController

extension MainFormViewController: IMainFormViewController {
    func showCommonSheet(state: CommonSheetState, animatePullableContainerUpdates: Bool) {
        presentationState = .commonSheet
        currentAnchor = .contentBased

        commonSheetView.showOverlay(animated: true) {
            self.commonSheetView.set(state: state)

            self.pullableContentDelegate?.updateHeight(
                animated: animatePullableContainerUpdates,
                alongsideAnimation: { self.commonSheetView.hideOverlay(animated: !animatePullableContainerUpdates) }
            )
        }
    }

    func hideCommonSheet() {
        presentationState = .tableView
        currentAnchor = .contentBased
        tableView.setContentOffset(.zero, animated: false)

        commonSheetView.showOverlay(animated: true) {
            self.commonSheetView.set(state: .clear)

            self.pullableContentDelegate?.updateHeight(
                animated: true,
                alongsideAnimation: { self.commonSheetView.hideOverlay(animated: false) }
            )
        }
    }

    func reloadData() {
        tableView.reloadData()
    }

    func insertRows(at indexPaths: [IndexPath]) {
        tableView.beginUpdates()
        tableView.insertRows(at: indexPaths, with: .fade)
        tableView.endUpdates()
    }

    func deleteRows(at indexPaths: [IndexPath]) {
        tableView.beginUpdates()
        tableView.deleteRows(at: indexPaths, with: .fade)
        tableView.endUpdates()
    }

    func hideKeyboard() {
        view.endEditing(true)
    }

    func closeView() {
        dismiss(animated: true, completion: presenter.viewWasClosed)
    }
}

// MARK: - ICommonSheetViewDelegate

extension MainFormViewController: ICommonSheetViewDelegate {
    func commonSheetViewDidTapPrimaryButton(_ commonSheetView: CommonSheetView) {
        presenter.commonSheetViewDidTapPrimaryButton()
    }

    func commonSheetViewDidTapSecondaryButton(_ commonSheetView: CommonSheetView) {
        presenter.commonSheetViewDidTapSecondaryButton()
    }
}

// MARK: - IPullableContainerContent

extension MainFormViewController: IPullableContainerContent {
    func pullableContainerDidRequestScrollView(_ contentDelegate: IPullableContainerСontentDelegate) -> UIScrollView? {
        tableView
    }

    func pullableContainerDidRequestNumberOfAnchors(_ contentDelegate: IPullableContainerСontentDelegate) -> Int {
        anchors.count
    }

    func pullableContainerDidRequestCurrentAnchorIndex(_ contentDelegate: IPullableContainerСontentDelegate) -> Int {
        anchors.firstIndex(of: currentAnchor) ?? .zero
    }

    func pullableContainer(_ contentDelegate: IPullableContainerСontentDelegate, didChange currentAnchorIndex: Int) {
        currentAnchor = anchors[currentAnchorIndex]
    }

    func pullabeContainer(_ contentDelegate: IPullableContainerСontentDelegate, canReachAnchorAt index: Int) -> Bool {
        switch presentationState {
        case .commonSheet:
            return false
        case .tableView:
            return true
        }
    }

    func pullableContainer(
        _ contentDelegate: IPullableContainerСontentDelegate,
        didRequestHeightForAnchorAt index: Int,
        availableSpace: CGFloat
    ) -> CGFloat {
        switch (anchors[index], presentationState) {
        case (.contentBased, .tableView):
            return tableContentProvider.pullableContainerHeight(
                for: presenter.allCells(),
                in: tableView,
                availableSpace: availableSpace
            )
        case (.contentBased, .commonSheet):
            return commonSheetView.estimatedHeight
        case (.expanded, _):
            return availableSpace
        }
    }

    func pullableContainer(_ contentDelegate: IPullableContainerСontentDelegate, didDragWithOffset offset: CGFloat) {
        hideKeyboard()
    }

    func pullableContainerWasClosed(_ contentDelegate: IPullableContainerСontentDelegate) {
        presenter.viewWasClosed()
    }
}

// MARK: - UITableViewDataSource

extension MainFormViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableContentProvider.dequeueCell(
            from: tableView,
            at: indexPath,
            withType: presenter.cellType(at: indexPath)
        )
    }
}

// MARK: - UITableViewDelegate

extension MainFormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.didSelectRow(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableContentProvider.height(for: presenter.cellType(at: indexPath), in: tableView)
    }
}

// MARK: - ThreeDSWebFlowDelegate

extension MainFormViewController: ThreeDSWebFlowDelegate {
    func hiddenWebViewToCollect3DSData() -> WKWebView {
        hiddenWebView
    }

    func sourceViewControllerToPresent() -> UIViewController? {
        self
    }
}

// MARK: IMainFormPresenter + Helpers

private extension IMainFormPresenter {
    func allCells() -> [MainFormCellType] {
        (0 ..< numberOfRows()).map { cellType(at: IndexPath(row: $0, section: .zero)) }
    }
}
