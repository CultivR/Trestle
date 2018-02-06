//
//  Button.swift
//  Trestle
//
//  Created by Jordan Kay on 6/20/17.
//  Copyright © 2017 Cultivr. All rights reserved.
//

open class Button: UIButton, TouchTargetModifying {
    @IBInspectable public var toggledImage: UIImage?
    
    @IBInspectable public var text: String? {
        get {
            return storedText
        }
        set {
            storedText = newValue
            content?.updateText(animated: false)
        }
    }
    
    @IBInspectable public var toggledText: String? {
        didSet {
            content?.updateText()
        }
    }
    
    @IBInspectable public var detailText: String? {
        didSet {
            content?.updateDetailText()
        }
    }
    
    public var textSize: CGFloat? {
        get {
            return content?.textLabel?.font.pointSize
        }
        set {
            guard let size = newValue, let textLabel = content?.textLabel else { return }
            textLabel.font = UIFont(descriptor: textLabel.font.fontDescriptor, size: size)
        }
    }
    
    public var detailTextSize: CGFloat? {
        get {
            return content?.detailTextLabel?.font.pointSize
        }
        set {
            guard let size = newValue, let detailTextLabel = content?.detailTextLabel else { return }
            detailTextLabel.font = UIFont(descriptor: detailTextLabel.font.fontDescriptor, size: size)
        }
    }
    
    @IBInspectable public private(set) var styleID: Int = 0
    @IBInspectable public private(set) var topTouchOutset: CGFloat = 0
    @IBInspectable public private(set) var leftTouchOutset: CGFloat = 0
    @IBInspectable public private(set) var bottomTouchOutset: CGFloat = 0
    @IBInspectable public private(set) var rightTouchOutset: CGFloat = 0
    
    @IBInspectable private(set) var icon: UIImage?
    
    @IBInspectable private var highlightedIcon: UIImage?
    @IBInspectable private var delaysTouchDown: Bool = true
    @IBInspectable private var roundedCorners: UInt = UIRectCorner.allCorners.rawValue

    var isToggled: Bool {
        return buttonState.toggledState
    }
    
    private var content: ButtonContent?
    private var storedText: String?
    private var defaultAlpha: CGFloat!
    private var defaultImage: UIImage!
    
    lazy private var buttonState = ButtonState(delegate: self)
    
    // MARK: UIView
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: NSCoding
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        decodeProperties(from: coder) {
            text = coder.decodeObject(forKey: "storedText") as? String
            let actions = coder.decodeObject(forKey: "actions") as? [String]
            actions?.forEach { addTarget(nil, action: Selector($0), for: .touchUpInside) }
        }
    }
}

extension Button {
    // MARK: UIView
    open override var intrinsicContentSize: CGSize {
        return content?.systemLayoutSizeFitting(bounds.size) ?? super.intrinsicContentSize
    }
    
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if defaultAlpha == nil {
            defaultAlpha = alpha
            defaultImage = image(for: .normal)
        }
        
        if hasStyle && content == nil {
            setupContent()
            setupContentTouchEvents()
            updateEnabledAlpha()
        }
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let touchTarget = UIEdgeInsetsInsetRect(bounds, touchInsets)
        if touchTarget.contains(point) {
            if !delaysTouchDown && !isHighlighted {
                // Use initial point-inside calculation for non-delayed touch down
                toggleHighlighted(true, animated: false)
            }
            return true
        }
        return false
    }
    
    // MARK: UIControl
    open override var isHighlighted: Bool {
        get {
            return hasStyle ? buttonState.highlightedState : super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
        }
    }
    
    open override var isEnabled: Bool {
        didSet {
            updateEnabledAlpha()
        }
    }
    
    // MARK: NSCoding
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        encodeProperties(with: coder) {
            coder.encode(storedText, forKey: "storedText")
            coder.encode(actions(forTarget: nil, forControlEvent: .touchUpInside), forKey: "actions")
        }
    }
}

public extension Button {
    func updateText(_ text: String, animated: Bool) {
        if animated {
            storedText = text
            content!.updateText(animated: true)
        } else {
            self.text = text
        }
    }
    
    func toggle() {
        buttonState.toggle()
    }
    
    func update(with state: ToggleAsyncState, allowsDisable: Bool = false) {
        switch state {
        case .on, .off:
            isEnabled = true
            buttonState.toggle(to: state == .on)
        case .turningOn, .turningOff:
            isEnabled = !allowsDisable
        }
    }
    
    func update<T>(with state: LoadingState<T>, animated: Bool = true, allowsDisable: Bool = true) {
        let loading: Bool
        switch state {
        case .loading:
            loading = true
        default:
            loading = false
        }
        if loading != buttonState.loadingState {
            toggleLoading(animated: animated, allowsDisable: allowsDisable)
        }
    }
    
    func update<T>(with state: ExistenceState<T>, animated: Bool = true, allowsDisable: Bool = true) {
        if state.isChanging != buttonState.loadingState {
            toggleLoading(animated: animated, allowsDisable: allowsDisable)
        }
    }
    
    func updateSubmission<T, U, V>(with state: SubmissionState<T, U, V>, animated: Bool = true, allowsDisable: Bool = true) {
        let submitting: Bool
        switch state {
        case .ableToSubmit:
            isEnabled = true
            submitting = false
        case .unableToSubmit:
            isEnabled = false
            submitting = false
        case .submitting:
            submitting = true
        default:
            submitting = false
        }
        if submitting != buttonState.loadingState {
            toggleLoading(animated: animated, allowsDisable: allowsDisable)
        }
    }
}

extension Button: ButtonStateDelegate {
    func state(_ state: ButtonState, didToggle toggled: Bool) {
        if let content = content {
            content.updateToggle(animated: true)
        } else if let toggledImage = toggledImage {
            let image = toggled ? toggledImage : defaultImage
            setImage(image, for: .normal)
        }
    }
}

private extension Button {
    var hasStyle: Bool {
        return self is Styled
    }
    
    func setupContent() {
        guard let variant = (self as? Styled)?.variant else { return }
        content = addContent(ofType: ButtonContent.self, withFrame: frame, variantID: variant.rawValue)
        content!.roundedCorners = roundedCorners
    }
    
    func setupContentTouchEvents() {
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        addTarget(self, action: #selector(touchDragEnter), for: .touchDragEnter)
        addTarget(self, action: #selector(touchDragExit), for: .touchDragExit)
        addTarget(self, action: #selector(touchCancel), for: .touchCancel)
    }
    
    func updateEnabledAlpha() {
        guard let content = content, hasStyle else { return }
        let showsDisabled = !isEnabled && !buttonState.loadingState
        
        if !content.updateBackgroundShape(disabled: showsDisabled) {
            alpha = defaultAlpha * (showsDisabled ? content.disabledAlpha : 1)
        }
    }
    
    func toggleHighlighted(_ highlighted: Bool, animated: Bool) {
        buttonState.toggleHighlighted()
        content!.updateBackgroundShape(highlighted: highlighted, animated: animated)
        if let iconView = content!.iconView, let highlightedIcon = highlightedIcon {
            iconView.crossfade(if: animated) {
                $0.image = highlighted ? highlightedIcon : self.icon
            }
        }
    }
    
    func toggleLoading(animated: Bool = true, allowsDisable: Bool = true) {
        buttonState.toggleLoading()
        
        let loading = buttonState.loadingState
        content!.update(loading: loading, animated: animated)
        isEnabled = !loading || !allowsDisable
    }
    
    @objc func touchDown() {
        guard delaysTouchDown else { return }
        toggleHighlighted(true, animated: false)
    }
    
    @objc func touchUpInside() {
        if content!.toggles {
            buttonState.toggleHighlighted()
        } else {
            // Give button a chance to display highlighted state from touch down
            delayUntilNextRunLoop {
                self.toggleHighlighted(false, animated: self.content!.animatesTouchUpInside)
            }
        }
    }
    
    @objc func touchDragEnter() {
        toggleHighlighted(true, animated: content!.animatesDragEnter)
    }
    
    @objc func touchDragExit() {
        toggleHighlighted(false, animated: content!.animatesDragExit)
    }
    
    @objc func touchCancel() {
        toggleHighlighted(false, animated: false)
    }
}
