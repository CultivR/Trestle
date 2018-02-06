//
//  ButtonBlock.swift
//  Cultivr
//
//  Created by Jordan Kay on 6/27/16.
//  Copyright © 2016 Cultivr. All rights reserved.
//

public final class ButtonContent: Block {
    @IBOutlet public private(set) var textLabel: UILabel? {
        didSet {
            updateText()
        }
    }
    
    @IBOutlet public private(set) var detailTextLabel: UILabel? {
        didSet {
            updateDetailText()
        }
    }
    
    @IBOutlet public private(set) var iconView: UIImageView? {
        didSet {
            updateIcon()
        }
    }
    
    @IBOutlet public private(set) var contentView: UIView?

    @IBInspectable private var isRounded: Bool = false
    @IBInspectable private var highlightColor: UIColor?
    @IBInspectable private var highlightedTextColor: UIColor?
    @IBInspectable private var highlightedBackgroundColor: UIColor?
    @IBInspectable private var highlightedBorderColor: UIColor?
    @IBInspectable private var toggledBackgroundColor: UIColor?
    @IBInspectable private var toggledHighlightedBackgroundColor: UIColor?
    @IBInspectable private var disabledTextColor: UIColor?
    @IBInspectable private var disabledBackgroundColor: UIColor?
    @IBInspectable private var disabledBorderColor: UIColor?
    @IBInspectable private var disabledInnerBorderColor: UIColor?
    @IBInspectable private var loadingSpinnerColor: UIColor?
    
    @IBInspectable private(set) var toggles: Bool = false
    @IBInspectable private(set) var animatesDragEnter: Bool = false
    @IBInspectable private(set) var animatesDragExit: Bool = true
    @IBInspectable private(set) var animatesTouchUpInside: Bool = true
    @IBInspectable private(set) var disabledAlpha: CGFloat = .defaultDisabledAlpha
    
    var roundedCorners: UInt = UIRectCorner.allCorners.rawValue {
        didSet {
            backgroundShape?.roundedCorners = roundedCorners
        }
    }
    
    private var defaultTextColor: UIColor?
    private var defaultBorderColor: UIColor?
    private var defaultInnerBorderColor: UIColor?
    private var defaultBackgroundColor: UIColor?
    
    private lazy var highlightView = backgroundShape.map { backgroundShape in
        UIView.create {
            $0.frame = bounds
            $0.backgroundColor = highlightColor
            $0.layer.masksToBounds = true
            $0.layer.cornerRadius = backgroundShape.cornerRadius
            addSubview($0)
        }
    }
    
    private lazy var loadingSpinner = loadingSpinnerColor.map { color in
        UIActivityIndicatorView.create {
            $0.color = color
            $0.alpha = 0
            $0.hidesWhenStopped = false
            $0.startAnimating()
            $0.isHidden = true
            addSubview($0)
        }
    }
}

public extension ButtonContent {
    // MARK: UIView
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        defaultTextColor = textLabel?.textColor
        defaultBackgroundColor = backgroundShape?.backgroundColor
        defaultBorderColor = backgroundShape?.borderColor
        defaultInnerBorderColor = backgroundShape?.innerBorderColor
        
        restoreViewsFromInterfaceBuilder()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundShape.do {
            if isRounded {
                $0.cornerRadius = $0.bounds.height / 2
            }
        }
        loadingSpinner.do {
            $0.center = center
            $0.frame = $0.frame.integral
        }
    }
}

extension ButtonContent {
    func updateText(animated: Bool = false) {
        guard let textLabel = textLabel, let button = button, let text = button.isToggled ? button.toggledText : button.text else { return }
        textLabel.crossfade(if: animated) {
            $0.text = text
        }
    }
    
    func updateDetailText() {
        guard let text = button?.detailText else { return }
        detailTextLabel?.text = text
    }
    
    func updateIcon() {
        guard let icon = button?.icon else { return }
        iconView?.image = icon
    }
    
    func updateBackgroundShape(highlighted: Bool, animated: Bool) {
        guard let button = button else { return }
        
        if highlightColor == nil {
            let color: UIColor?
            switch (highlighted, button.isToggled) {
            case (false, false):
                color = defaultBackgroundColor
            case (true, false):
                color = highlightedBackgroundColor
            case (false, true):
                color = toggledBackgroundColor
            case (true, true):
                color = toggledHighlightedBackgroundColor
            }
            backgroundShape?.crossfade(if: animated) {
                $0.backgroundColor = color
                if highlighted && button.isToggled {
                    $0.borderColor = color
                    $0.innerBorderColor = color
                } else {
                    $0.borderColor = highlighted ? (self.highlightedBorderColor ?? self.defaultBorderColor) : self.defaultBorderColor
                    $0.innerBorderColor = self.defaultInnerBorderColor
                }
            }
            if let highlightedTextColor = highlightedTextColor {
                [textLabel, detailTextLabel].forEach {
                    $0?.crossfade(if: animated) {
                        $0.textColor = highlighted ? highlightedTextColor : self.defaultTextColor
                    }
                }
            }
        } else {
            highlightView?.crossfade(if: animated) {
                $0.isHidden = !highlighted
            }
        }
    }
    
    func updateBackgroundShape(disabled: Bool) -> Bool {
        guard disabledTextColor != nil || disabledBackgroundColor != nil || disabledBorderColor != nil || disabledInnerBorderColor != nil else { return false }

        if let color = disabledTextColor {
            textLabel?.textColor = disabled ? color : defaultTextColor
        }
        if let color = disabledBackgroundColor {
            backgroundShape?.backgroundColor = disabled ? color : defaultBackgroundColor
        }
        if let color = disabledBorderColor {
            backgroundShape?.borderColor = disabled ? color : defaultBorderColor
        }
        if let color = disabledInnerBorderColor {
            backgroundShape?.innerBorderColor = disabled ? color : defaultInnerBorderColor
        }
        return true
    }
    
    func updateToggle(animated: Bool) {
        guard let button = button, let backgroundShape = backgroundShape else { return }
        
        let color = button.isToggled ? toggledBackgroundColor : defaultBackgroundColor
        backgroundShape.crossfade(if: animated) {
            self.updateText()
            $0.backgroundColor = color
            $0.borderColor = self.defaultBorderColor
            $0.innerBorderColor = self.defaultInnerBorderColor
        }
    }
    
    func update(loading: Bool, animated: Bool) {
        guard let view = contentView ?? textLabel, let loadingSpinner = loadingSpinner else { return }
        if animated {
            delayUntilNextRunLoop {
                view.crossfade { $0.isHidden = loading }
                loadingSpinner.crossfade { $0.isHidden = !loading }
            }
        } else {
            view.isHidden = loading
            loadingSpinner.isHidden = !loading
        }
    }
}

private extension ButtonContent {
    var button: Button? {
        return superview as? Button
    }
    
    var backgroundShape: Shape? {
        return firstSubview(ofType: Shape.self)
    }
    
    func restoreViewsFromInterfaceBuilder() {
        loadingSpinner?.alpha = 1
    }
}

private extension CGFloat {
    static let defaultDisabledAlpha: CGFloat = 0.5
}
