//
//  IPayButtonViewOutput.swift
//  TinkoffASDKUI
//
//  Created by r.akhmadeev on 08.02.2023.
//

import Foundation

protocol IPayButtonViewOutput: AnyObject {
    var view: IPayButtonViewInput? { get set }
    func payButtonTapped()
}
