//
//  Delay.swift
//  Trestle
//
//  Created by Jordan Kay on 8/9/17.
//  Copyright © 2017 Cultivr. All rights reserved.
//

public func delayUntilNextRunLoop(action: @escaping () -> Void) {
    DispatchQueue.main.async(execute: action)
}

public func delay(_ delay: TimeInterval, action: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
}

public extension DispatchWorkItem {
    func perform(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: self)
    }
}
