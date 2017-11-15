//
//  NavigationItem.swift
//  Trestle
//
//  Created by Jordan Kay on 12/1/17.
//  Copyright © 2017 Squareknot. All rights reserved.
//

public extension UIBarButtonItem {
    var contentView: UIView? {
        return value(forKey: "view") as? UIView
    }
}
