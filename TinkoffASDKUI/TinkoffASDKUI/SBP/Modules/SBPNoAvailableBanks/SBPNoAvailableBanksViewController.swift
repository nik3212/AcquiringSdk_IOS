//
//
//  SBPNoAvailableBanksViewController.swift
//
//  Copyright (c) 2021 Tinkoff Bank
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


import UIKit

final class SBPNoAvailableBanksViewController: UIViewController, CustomViewLoadable {
    typealias CustomView = SBPNoAvailableBanksView
    
    private let style: SBPNoAvailableBanksView.Style
    private let urlOpener: URLOpener
    
    init(style: SBPNoAvailableBanksView.Style,
         urlOpener: URLOpener) {
        self.style = style
        self.urlOpener = urlOpener
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = SBPNoAvailableBanksView(style: style)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
}

private extension SBPNoAvailableBanksViewController {
    func setup() {
        customView.imageView.image = UIImage(named: "empty_banks", in: .uiResources, compatibleWith: nil)
        setupLocalization()
        setupButtons()
        setupNavigationButton()
    }
    
    func setupLocalization() {
        customView.titleLabel.text = AcqLoc.instance.localize(
            "SBP.EmptyBanks.Title"
        )
        customView.descriptionLabel.text = AcqLoc.instance.localize(
            "SBP.EmptyBanks.Description"
        )
        customView.confirmButton.setTitle(AcqLoc.instance.localize(
            "SBP.EmptyBanks.ConfirmationButton.Title"
        ), for: .normal)
        customView.informationButton.setTitle(AcqLoc.instance.localize(
            "SBP.EmptyBanks.InformationButton.Title"
        ), for: .normal)
    }
    
    func setupButtons() {
        customView.confirmButton.addTarget(self,
                                           action: #selector(close),
                                           for: .touchUpInside)
        
        customView.informationButton.addTarget(self,
                                               action: #selector(openInformation),
                                               for: .touchUpInside)
    }
    
    func setupNavigationButton() {
        let closeButton: UIBarButtonItem
        if #available(iOS 13.0, *) {
            closeButton = UIBarButtonItem(barButtonSystemItem: .close,
                                          target: self,
                                          action: #selector(close))
        } else {
            closeButton = UIBarButtonItem(title: AcqLoc.instance.localize("TinkoffAcquiring.button.close"),
                                          style: .done,
                                          target: self,
                                          action: #selector(close))
        }
        navigationItem.rightBarButtonItem = closeButton
    }
    
    @objc func close() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func openInformation() {
        urlOpener.openUrl(.informationURL)
    }
}

private extension URL {
    static var informationURL: URL {
        URL(string: "https://sbp.nspk.ru/participants/")!
    }
}