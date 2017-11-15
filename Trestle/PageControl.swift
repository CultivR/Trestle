//
//  PageControl.swift
//  DISC
//
//  Created by Jordan Kay on 1/26/18.
//  Copyright © 2018 Cultivr. All rights reserved.
//

public class PageControl: UIPageControl {
    @IBInspectable private var size: CGFloat = .defaultSize
    @IBInspectable private var spacing: CGFloat = .defaultSpacing
    
    // MARK: UIView
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutPips()
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

private extension PageControl {
    func layoutPips() {
        let width = CGFloat(numberOfPages - 1) * spacing + size
        let x = floor((bounds.size.width - width) / 2)
        let y = floor((bounds.size.height - size) / 2)
        for (index, subview) in subviews.enumerated() {
            subview.frame.origin.x = x + spacing * CGFloat(index)
        }
        
        let scale = size / .defaultSize
        subviews.forEach {
            $0.frame.origin.y = y
            $0.transform = .init(scaleX: scale, y: scale)
        }
    }
}

private extension CGFloat {
    static let defaultSize: CGFloat = 7
    static let defaultSpacing: CGFloat = 16
}
