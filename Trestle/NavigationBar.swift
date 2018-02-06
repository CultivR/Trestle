//
//  NavigationBar.swift
//  Trestle
//
//  Created by Jordan Kay on 11/15/17.
//  Copyright © 2017 Cultivr. All rights reserved.
//

public final class NavigationBar: UINavigationBar {
    @IBInspectable private var isTransparent: Bool = false
    
    // MARK: UIView
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: NSCoding
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        decodeProperties(from: coder)
    }
}

public extension NavigationBar {
    // MARK: UIView
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if isTransparent {
            removeBackground()
        }
    }

    // MARK: NSCoding
    override func encode(with coder: NSCoder) {
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
