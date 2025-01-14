//
//  ISwitchViewOutput.swift
//  TinkoffASDKUI
//
//  Created by Aleksandr Pravosudov on 23.01.2023.
//

protocol ISwitchViewOutput: AnyObject {
    var view: ISwitchViewInput? { get set }

    func switchButtonValueChanged(to isOn: Bool)
}
