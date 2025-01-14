//
//  IDispatchQueue.swift
//  TinkoffASDKUI
//
//  Created by Aleksandr Pravosudov on 21.04.2023.
//

import Foundation

protocol IDispatchQueue {
    func async(
        group: DispatchGroup?,
        qos: DispatchQoS,
        flags: DispatchWorkItemFlags,
        execute work: @escaping @convention(block) () -> Void
    )

    func asyncDeduped(target: AnyObject, after delay: TimeInterval, execute work: @escaping @convention(block) () -> Void)
}

extension IDispatchQueue {
    func async(
        group: DispatchGroup? = nil,
        qos: DispatchQoS = .unspecified,
        flags: DispatchWorkItemFlags = [],
        execute work: @escaping @convention(block) () -> Void
    ) {
        async(group: group, qos: qos, flags: flags, execute: work)
    }
}

extension DispatchQueue: IDispatchQueue {}
