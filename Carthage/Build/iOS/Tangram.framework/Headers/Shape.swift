//
//  Shape.swift
//  Tangram
//
//  Created by Jordan Kay on 5/30/17.
//  Copyright © 2017 Squareknot. All rights reserved.
//

import Mensa
import Then
import UIKit

@IBDesignable open class Shape: UIView {
    @IBInspectable public var cornerRadius: CGFloat = 0 {
        didSet {
            guard cornerRadius != oldValue else { return }
            setNeedsUpdateBackgroundImage()
        }
    }
    
    @IBInspectable public var roundedCorners: UInt = UIRectCorner.allCorners.rawValue {
        didSet {
            guard roundedCorners != oldValue else { return }
            setNeedsUpdateBackgroundImage()
        }
    }
    
    @IBInspectable public var borderedEdges: UInt = UIRectEdge.all.rawValue {
        didSet {
            guard borderedEdges != oldValue else { return }
            setNeedsUpdateBackgroundImage()
        }
    }
    
    @IBInspectable public var borderWidth: CGFloat = 0 {
        didSet {
            guard borderWidth != oldValue else { return }
            setNeedsUpdateBackgroundImage()
        }
    }
    
    @IBInspectable public var borderColor: UIColor? {
        didSet {
            guard borderColor != oldValue else { return }
            setNeedsUpdateBackgroundImage()
        }
    }
    
    @IBInspectable public var borderHugsEdge: Bool = false {
        didSet {
            guard borderHugsEdge != oldValue else { return }
            setNeedsUpdateBackgroundImage()
        }
    }
    
    @IBInspectable public var innerBorderWidth: CGFloat = 0 {
        didSet {
            guard innerBorderWidth != oldValue else { return }
            setNeedsUpdateBackgroundImage()
        }
    }
    
    @IBInspectable public var innerBorderColor: UIColor? {
        didSet {
            guard innerBorderColor != oldValue else { return }
            setNeedsUpdateBackgroundImage()
        }
    }
    
    @IBInspectable public var backgroundImage: UIImage? {
        get {
            return storedBackgroundImage
        }
        set {
            storedBackgroundImage = newValue
            setNeedsUpdateBackgroundImage()
        }
    }
    
    public var storedBackgroundImage: UIImage?
    public var contentFrame: CGRect {
        return bounds
    }
    
    public final var image: UIImage? {
        get {
            return backgroundImage
        }
        set {
            backgroundImage = newValue
        }
    }
    
    public final var fullImage: UIImage? {
        updateBackgroundImage()
        return backgroundView.image
    }
    
    final lazy var backgroundView: UIImageView = UIImageView().then {
        $0.frame = self.bounds
        $0.isUserInteractionEnabled = true
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        $0.contentMode = .center
        self.insertSubview($0, at: 0)
    }
    
    fileprivate var didUpdateAfterLayout = false
    fileprivate var storedBackgroundColor: UIColor?
    fileprivate static var borderImageCache: [String: UIImage] = [:]
    
    private var lastProperties: BackgroundImageProperties!
    
    func updateBackgroundImage(forChangedValue: Bool = true) {
        guard bounds.width != 0 && bounds.height != 0 else { return }
#if !TARGET_INTERFACE_BUILDER
        let prematureChange = forChangedValue && backgroundView.image == nil && window == nil
        guard !prematureChange && lastProperties != currentProperties else { return }
        lastProperties = currentProperties
#endif
        
        if Thread.isMainThread { print("^ \(self)") }
        backgroundView.image = UIImage.rendering(size: bounds.size, opaque: false) { context in
            if !borderHugsEdge {
                let path = maskPath(forRect: contentFrame).cgPath
                context.addPath(path)
                context.clip()
            }
            
            if let color = backgroundColor {
                color.set()
                UIRectFill(contentFrame)
            }
            
            backgroundImage?.draw(in: imageFrame)
            innerBorderImage?.draw(in: borderFrame(inner: true))
            borderImage?.draw(in: self.borderFrame(inner: false))
        }
    }
    
    // MARK: UIView
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    open override var frame: CGRect {
        didSet {
            if oldValue != frame && oldValue.size != .zero && frame.size != .zero {
                updateBackgroundImage()
            }
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if !didUpdateAfterLayout {
            updateBackgroundImage(forChangedValue: window != nil)
            didUpdateAfterLayout = true
        }
    }
    
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        
        guard window != nil else { return }
        if superview is UIWindow {
            super.backgroundColor = backgroundColor
        }
    }
    
    open override var backgroundColor: UIColor? {
        get {
            return storedBackgroundColor
        }
        set {
            storedBackgroundColor = newValue
            setNeedsUpdateBackgroundImage()
        }
    }
    
    // MARK: NSCoding
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        decodeProperties(from: coder) {
            storedBackgroundColor = coder.decodeObject(forKey: "storedBackgroundColor") as? UIColor
        }
    }
    
    override open func encode(with coder: NSCoder) {
        super.encode(with: coder)
        encodeProperties(with: coder) {
            coder.encode(storedBackgroundColor, forKey: "storedBackgroundColor")
        }
    }
}

private extension Shape {
    struct BackgroundImageProperties {
        let frame: CGRect
        let cornerRadius: CGFloat
        let roundedCorners: UInt
        let borderedEdges: UInt
        let borderWidth: CGFloat
        let borderColor: UIColor?
        let borderHugsEdge: Bool
        let innerBorderWidth: CGFloat
        let innerBorderColor: UIColor?
        let backgroundColor: UIColor?
        let backgroundImage: UIImage?
    }
    
    var borderImage: UIImage? {
        return borderImage(forWidth: borderWidth, color: borderColor)
    }
    
    var innerBorderImage: UIImage? {
        return borderImage(forWidth: innerBorderWidth + borderWidth, color: innerBorderColor)
    }
    
    var imageFrame: CGRect {
        guard let image = backgroundImage else { return .zero }
        
        let inset = borderWidth + innerBorderWidth
        let widthRatio = image.size.width / contentFrame.width
        let heightRatio = image.size.height / contentFrame.height
        let width = image.size.width / heightRatio
        let height = image.size.height / widthRatio
        let x = (contentFrame.width - width) / 2
        let y = (contentFrame.height - height) / 2
        
        var rect: CGRect = .zero
        if x <= 0 {
            rect = CGRect(x: x, y: 0, width: width, height: contentFrame.height)
        } else if y <= 0 {
            rect = CGRect(x: 0, y: y, width: contentFrame.width, height: height)
        } else {
            rect = contentFrame
        }
        return rect.insetBy(dx: inset, dy: inset)
    }
    
    var currentProperties: BackgroundImageProperties {
        return BackgroundImageProperties(frame: frame, cornerRadius: cornerRadius, roundedCorners: roundedCorners, borderedEdges: borderedEdges, borderWidth: borderWidth, borderColor: borderColor, borderHugsEdge: borderHugsEdge, innerBorderWidth: innerBorderWidth, innerBorderColor: innerBorderColor, backgroundColor: backgroundColor, backgroundImage: backgroundImage)
    }
    
    func setNeedsUpdateBackgroundImage() {
        didUpdateAfterLayout = false
        setNeedsLayout()
    }
    
    func maskPath(forRect rect: CGRect) -> UIBezierPath {
        if cornerRadius > 0 {
            let corners = UIRectCorner(rawValue: roundedCorners)
            return UIBezierPath(rect: rect, cornerRadius: cornerRadius, roundedCorners: corners)
        }
        return UIBezierPath(rect: rect)
    }
    
    func borderInsets(forWidth width: CGFloat, rounded: Bool) -> UIEdgeInsets {
        let inset = rounded ? cornerRadius - .pixelWidth : width
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    func borderFrame(inner: Bool) -> CGRect {
        var insets: UIEdgeInsets = .zero
        var width = borderWidth
        if inner {
            width += innerBorderWidth
        }
        
        if (borderedEdges & UIRectEdge.top.rawValue) == 0 {
            insets.top -= width
        }
        if (borderedEdges & UIRectEdge.left.rawValue) == 0 {
            insets.left -= width
        }
        if (borderedEdges & UIRectEdge.bottom.rawValue) == 0 {
            insets.bottom -= width
        }
        if (borderedEdges & UIRectEdge.right.rawValue) == 0 {
            insets.right -= width
        }
        
        return UIEdgeInsetsInsetRect(CGRect(x: 0, y: 0, width: contentFrame.width, height: contentFrame.height), insets)
    }
    
    func borderImage(forWidth width: CGFloat, color: UIColor!) -> UIImage? {
        guard color != nil else { return nil }
        
        var width = width
        if width < 1 {
            width = .pixelWidth
        }
        
        let key = "\(width)\(color)\(cornerRadius)\(roundedCorners)"
        if let cachedBorderImage = type(of: self).borderImageCache[key] {
            return cachedBorderImage
        }
        
        let rounded = cornerRadius > width
        let side = rounded ? cornerRadius * 2 : width * 2 + .pixelWidth
        let rect = CGRect(x: 0, y: 0, width: side, height: side)
        let borderRect = rect.insetBy(dx: width, dy: width)
        let insets = borderInsets(forWidth: width, rounded: rounded)
        
        let image = UIImage.rendering(size: rect.size, opaque: false) { context in
            let context = UIGraphicsGetCurrentContext()!
            context.setFillColor(color.cgColor)
            context.fill(rect)
            context.setBlendMode(.clear)
            if rounded {
                let radius = borderRect.width / 2
                let corners = UIRectCorner(rawValue: self.roundedCorners)
                let path = UIBezierPath(rect: borderRect, cornerRadius: radius, roundedCorners: corners)
                context.addPath(path.cgPath)
                context.fillPath()
            } else {
                context.fill(borderRect)
            }
        }
        
        let borderImage = image.resizableImage(withCapInsets: insets)
        type(of: self).borderImageCache[key] = borderImage
        return borderImage
    }
}

extension Shape.BackgroundImageProperties: Equatable {
    static func ==(lhs: Shape.BackgroundImageProperties, rhs: Shape.BackgroundImageProperties) -> Bool {
        return
            lhs.frame == rhs.frame &&
            lhs.cornerRadius == rhs.cornerRadius &&
            lhs.roundedCorners == rhs.roundedCorners &&
            lhs.borderedEdges == rhs.borderedEdges &&
            lhs.borderWidth == rhs.borderWidth &&
            lhs.borderColor == rhs.borderColor &&
            lhs.borderHugsEdge == rhs.borderHugsEdge &&
            lhs.innerBorderWidth == rhs.innerBorderWidth &&
            lhs.innerBorderColor == rhs.innerBorderColor &&
            lhs.backgroundColor == rhs.backgroundColor &&
            lhs.backgroundImage == rhs.backgroundImage
    }
}

extension CGFloat {
    static let pixelWidth = 1 / UIScreen.main.scale
}
