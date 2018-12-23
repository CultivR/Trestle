//
//  TabBar.swift
//  Trestle
//
//  Created by Jordan Kay on 10/25/17.
//  Copyright © 2017 Cultivr. All rights reserved.
//

public final class TabBar: UITabBar {
    @IBOutlet public private(set) var centerView: UIView?
    
    @IBInspectable private var innerAdjustment: CGFloat = 0
    @IBInspectable private var outerAdjustment: CGFloat = 0
    
    private var offsets: [CGFloat]!
    
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

extension TabBar {
    // MARK: UIView
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        setupCenterView()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutCenterButton()
        layoutSurroundingButtons()
    }
    
    // MARK: NSCoding
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        encodeProperties(with: coder)
    }
}

private extension TabBar {
    var buttons: [UIControl] {
        return subviews.compactMap { $0 as? UIControl }.sorted { $0.frame.minX < $1.frame.minX }
    }
    
    var surroundingButtons: [UIControl]? {
        return centerView.map { view in buttons.filter { $0 != view } }
    }
    
    func setupCenterView() {
        if let view = centerView, view.superview == nil {
            addSubview(view)
        }
    }
    
    func layoutCenterButton() {
        centerView.do {
            $0.center = superview!.convert(center, to: self)
            $0.frame = $0.frame.integral
        }
    }
    
    func layoutSurroundingButtons() {
        guard let buttons = surroundingButtons else { return }
        
        if offsets == nil {
            offsets = buttons.map { $0.frame.minX }
        }
        for (index, button) in buttons.enumerated() {
            let offset = offsets[index]
            let direction: CGFloat = index < (buttons.count / 2) ? -1 : 1
            let outer = index == 0 || index == buttons.count - 1
            let adjust = outer ? outerAdjustment : innerAdjustment
            button.frame.origin.x = offset + direction * adjust
        }
    }
}
