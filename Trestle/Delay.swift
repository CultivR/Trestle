//
//  Delay.swift
//  Trestle
//
//  Created by Jordan Kay on 8/9/17.
//  Copyright © 2017 Squareknot. All rights reserved.
//

public func delay(_ delay: TimeInterval, action: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
}

public func delayUntilNextRunLoop(_ action: @escaping () -> Void) {
    DispatchQueue.main.async(execute: action)
}
