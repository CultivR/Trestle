//
//  Button.swift
//  Mensa
//
//  Created by Jordan Kay on 5/15/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

open class Button: UIButton {
    // MARK: NSCoding
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        let actions = coder.decodeObject(forKey: "actions") as? [String]
        actions?.forEach { addTarget(nil, action: Selector($0), for: .touchUpInside) }
    }
    
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(actions(forTarget: nil, forControlEvent: .touchUpInside), forKey: "actions")
    }
}
