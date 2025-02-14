//
//  RecurrentPaymentAssembly.swift
//  TinkoffASDKUI
//
//  Created by Aleksandr Pravosudov on 03.03.2023.
//

import TinkoffASDKCore
import UIKit

final class RecurrentPaymentAssembly: IRecurrentPaymentAssembly {

    // MARK: Dependencies

    private let acquiringSdk: AcquiringSdk
    private let paymentControllerAssembly: IPaymentControllerAssembly
    private let cardsControllerAssembly: ICardsControllerAssembly

    // MARK: Initialization

    init(
        acquiringSdk: AcquiringSdk,
        paymentControllerAssembly: IPaymentControllerAssembly,
        cardsControllerAssembly: ICardsControllerAssembly
    ) {
        self.acquiringSdk = acquiringSdk
        self.paymentControllerAssembly = paymentControllerAssembly
        self.cardsControllerAssembly = cardsControllerAssembly
    }

    // MARK: ISBPPaymentSheetAssembly

    func build(
        paymentFlow: PaymentFlow,
        rebillId: String,
        failureDelegate: IRecurrentPaymentFailiureDelegate?,
        moduleCompletion: PaymentResultCompletion?
    ) -> UIViewController {
        let paymentController = paymentControllerAssembly.paymentController()
        let cardsController = paymentFlow.customerKey.map { cardsControllerAssembly.cardsController(customerKey: $0) }

        let presenter = RecurrentPaymentPresenter(
            paymentController: paymentController,
            cardsController: cardsController,
            paymentFlow: paymentFlow,
            rebillId: rebillId,
            amount: paymentFlow.amount,
            failureDelegate: failureDelegate,
            moduleCompletion: moduleCompletion
        )

        let tableContentProvider = RecurrentPaymentTableContentProvider()

        let view = RecurrentPaymentViewController(presenter: presenter, tableContentProvider: tableContentProvider)
        presenter.view = view

        paymentController.delegate = presenter
        paymentController.webFlowDelegate = view

        let container = PullableContainerViewController(content: view)
        view.pullableContentDelegate = container

        return container
    }
}
