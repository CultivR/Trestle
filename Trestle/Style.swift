//
//  Style.swift
//  Trestle
//
//  Created by Jordan Kay on 5/2/18.
//  Copyright © 2018 Cultivr. All rights reserved.
//

public protocol Styled {
    var styleID: Int { get }
    
    static var variantType: ContentVariant.Type { get }
}

extension Styled {
    var variant: ContentVariant {
        return type(of: self).variantType.init(rawValue: styleID)!
    }
}

public protocol ContentVariant {
    var rawValue: Int { get }
    
    init?(rawValue: Int)
}
