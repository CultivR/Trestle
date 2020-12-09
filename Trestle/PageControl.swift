//
//  PageControl.swift
//  DISC
//
//  Created by Jordan Kay on 1/26/18.
//  Copyright © 2018 Cultivr. All rights reserved.
//

public final class PageControl: UIPageControl {
    public weak var delegate: PageControlDelegate!
    
    @IBInspectable private var size: CGFloat = .defaultSize
    @IBInspectable private var spacing: CGFloat = .defaultSpacing
    
    // MARK: UIView
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: NSCoding
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        decodeProperties(from: coder) {
            let actions = coder.decodeObject(forKey: "actions") as? [String]
            actions?.forEach { addTarget(nil, action: Selector($0), for: .touchUpInside) }
        }
    }
}

public extension PageControl {
    // MARK: UIResponder
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        let x = point.x - initialX
        let threshold = (spacing + size) / 2
        if x < currentX {
            guard currentPage > 0 && currentX - x > threshold else { return }
            delegate.pageControl(self, didTapToUpdateToPage: currentPage - 1)
        } else {
            guard currentPage < numberOfPages - 1 && x - currentX > threshold else { return }
            delegate.pageControl(self, didTapToUpdateToPage: currentPage + 1)
        }
    }

    // MARK: UIView
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutPips()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        sizePips()
    }
    
    // MARK: UIPageControl
    override var numberOfPages: Int {
        didSet {
            sizePips()
        }
    }
    
    // MARK: NSCoding
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        encodeProperties(with: coder) {
            coder.encode(actions(forTarget: nil, forControlEvent: .touchUpInside), forKey: "actions")
        }
    }
}

private extension PageControl {
    var distance: CGFloat {
        return spacing + size
    }
    
    var initialX: CGFloat {
        let width = distance * CGFloat(numberOfPages) + size
        let halfWidth = width / 2
        return round((bounds.size.width - width - halfWidth) / 2) + .defaultSize
    }
    
    var currentX: CGFloat {
        return CGFloat(currentPage) * distance + size / 2
    }
    
    func sizePips() {
        let scale = size / .defaultSize
        subviews.forEach {
            $0.transform = .init(scaleX: scale, y: scale)
        }
    }
    
    func layoutPips() {
        let y: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            subview.frame.origin.y = y
            subview.frame.origin.x = initialX + distance * CGFloat(index)
        }
    }
}

private extension CGFloat {
    static let defaultSize: CGFloat = 7
    static let defaultSpacing: CGFloat = 16
}

public protocol PageControlDelegate: class {
    func pageControl(_ pageControl: PageControl, didTapToUpdateToPage page: Int)
}
