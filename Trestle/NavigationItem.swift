//
//  NavigationItem.swift
//  Trestle
//
//  Created by Jordan Kay on 12/1/17.
//  Copyright © 2017 Cultivr. All rights reserved.
//

public extension UIBarButtonItem {
    var contentView: UIView? {
        return value(forKey: "view") as? UIView
    }
    
    func restoreImage() {
        guard let image = image else { return }
        self.image = image.withRenderingMode(.alwaysOriginal)
    }
}
