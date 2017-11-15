//
//  NavigationBar.swift
//  Trestle
//
//  Created by Jordan Kay on 11/15/17.
//  Copyright © 2017 Squareknot. All rights reserved.
//

import Tangram

public final class NavigationBar: UINavigationBar {
    @IBInspectable private var isTransparent: Bool = false
    
    // MARK: UIView
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if isTransparent {
            removeBackground()
        }
    }
    
    // MARK: NSCoding
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        decodeProperties(from: coder)
    }
    
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        encodeProperties(with: coder)
    }
}

private extension NavigationBar {
    func removeBackground() {
        let image = UIImage()
        shadowImage = image
        setBackgroundImage(image, for: .default)
    }
}
