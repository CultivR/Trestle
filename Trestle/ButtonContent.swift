//
//  ButtonBlock.swift
//  Squareknot
//
//  Created by Jordan Kay on 6/27/16.
//  Copyright © 2016 Squareknot. All rights reserved.
//

import Lilt
import Tangram

open class ButtonContent: Block {
    @IBOutlet public private(set) var loadingSpinner: UIActivityIndicatorView?
    
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

    @IBInspectable private var isRounded: Bool = false
    @IBInspectable private var highlightColor: UIColor?
    @IBInspectable private var highlightedTextColor: UIColor?
    @IBInspectable private var highlightedBackgroundColor: UIColor?
    @IBInspectable private var toggledBackgroundColor: UIColor?
    @IBInspectable private var toggledHighlightedBackgroundColor: UIColor?
    
    @IBInspectable private(set) var toggles: Bool = false
    @IBInspectable private(set) var animatesDragEnter: Bool = false
    @IBInspectable private(set) var animatesDragExit: Bool = true
    @IBInspectable private(set) var animatesTouchUpInside: Bool = true
    @IBInspectable private(set) var disabledAlpha: CGFloat = .defaultDisabledAlpha
    
    private var defaultTextColor: UIColor?
    private var defaultBorderColor: UIColor?
    private var defaultInnerBorderColor: UIColor?
    private var defaultBackgroundColor: UIColor?
    
    private lazy var highlightView: UIView? = {
        guard let backgroundShape = backgroundShape else { return nil }
        let view = UIView(frame: self.bounds)
        view.backgroundColor = self.highlightColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = backgroundShape.cornerRadius
        addSubview(view)
        return view
    }()
    
    func updateText(animated: Bool = false) {
        guard let textLabel = textLabel, let button = button, let text = button.isToggled ? button.toggledText : button.text else { return }
        textLabel.crossfade(if: animated) {
            $0.text = text
        }
    }
    
    func updateDetailText() {
        guard let detailText = button?.detailText else { return }
        detailTextLabel?.text = detailText
    }
    
    func updateBackgroundShape(highlighted: Bool, animated: Bool) {
        guard let button = button, let backgroundShape = backgroundShape else { return }
        
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
            backgroundShape.crossfade(if: animated) {
                $0.backgroundColor = color
                if highlighted && button.isToggled {
                    $0.borderColor = color
                    $0.innerBorderColor = color
                } else {
                    $0.borderColor = self.defaultBorderColor
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
        guard let textLabel = textLabel, let loadingSpinner = loadingSpinner else { return }
        if animated {
            delayUntilNextRunLoop {
                textLabel.crossfade { $0.isHidden = loading }
                loadingSpinner.crossfade { $0.isHidden = !loading }
            }
        } else {
            textLabel.isHidden = loading
            loadingSpinner.isHidden = !loading
        }
    }
    
    // MARK: UIView
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        
        defaultTextColor = textLabel?.textColor
        defaultBackgroundColor = backgroundShape?.backgroundColor
        defaultBorderColor = backgroundShape?.borderColor
        defaultInnerBorderColor = backgroundShape?.innerBorderColor
        
        restoreViewsFromInterfaceBuilder()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let backgroundShape = backgroundShape else { return }
        
        if isRounded {
            backgroundShape.cornerRadius = backgroundShape.bounds.height / 2
        }
    }
}

private extension ButtonContent {
    var button: Button? {
        return superview as? Button
    }
    
    var backgroundShape: Shape? {
        return subviews.first as? Shape
    }
    
    func restoreViewsFromInterfaceBuilder() {
        loadingSpinner?.alpha = 1
    }
}

private extension CGFloat {
    static let defaultDisabledAlpha: CGFloat = 0.5
}
