//
//  TouchTargetModifying.swift
//  Trestle
//
//  Created by Jordan Kay on 6/20/17.
//  Copyright © 2017 Squareknot. All rights reserved.
//

import UIKit

protocol TouchTargetModifying {
    var topTouchOutset: CGFloat { get }
    var leftTouchOutset: CGFloat { get }
    var bottomTouchOutset: CGFloat { get }
    var rightTouchOutset: CGFloat { get }
}

extension TouchTargetModifying {
    public var touchInsets: UIEdgeInsets {
        return UIEdgeInsets(top: -topTouchOutset, left: -leftTouchOutset, bottom: -bottomTouchOutset, right: -rightTouchOutset)
    }
}
