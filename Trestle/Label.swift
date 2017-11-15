//
//  Label.swift
//  Trestle
//
//  Created by Jordan Kay on 7/26/17.
//  Copyright © 2017 Squareknot. All rights reserved.
//

import Cipher
import Then

@IBDesignable public final class Label: UILabel {
    @IBInspectable private var kerning: CGFloat = 0
    @IBInspectable private var linePadding: CGFloat = 0
    
    @IBInspectable private var shadowRadius: CGFloat = 0 {
        didSet {
            layer.shadowRadius = shadowRadius
        }
    }
    
    @available(*, unavailable)
    init() {
        fatalError()
    }
    
    // MARK: UIView
    @available(*, unavailable)
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.shadowRadius = 0
    }
    
    public override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        if linePadding < 0 {
            size.height -= linePadding
        }
        return size
    }
    
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        updateAttributedText()
    }
    
    // MARK: UILabel
    public override var text: String? {
        didSet {
            updateAttributedText()
        }
    }
    
    public override var shadowColor: UIColor? {
        get {
            return layer.shadowColor.map { UIColor(cgColor: $0) }
        }
        set {
            if newValue != nil {
                layer.shadowOpacity = 1
            }
            layer.shadowColor = newValue?.cgColor
        }
    }
    
    public override var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    public override func drawText(in rect: CGRect) {
        var rect = rect
        if linePadding < 0 {
            rect.origin.y -= linePadding / 2
        }
        super.drawText(in: rect)
    }
    
    // MARK: NSCoding
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.shadowRadius = 0
        decodeProperties(from: coder)
    }
    
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        encodeProperties(with: coder)
    }
}

private extension Label {
    var style: NSMutableParagraphStyle {
        return .create {
            $0.alignment = textAlignment
            $0.lineBreakMode = lineBreakMode
            if linePadding < 0 {
                $0.lineSpacing = 0
                $0.maximumLineHeight = font.lineHeight + linePadding
            } else {
                $0.lineSpacing = linePadding
            }
        }
    }
    
    var attributes: [NSAttributedStringKey: Any] {
        return [
            .paragraphStyle: style,
            .kern: kerning
        ]
    }
    
    func updateAttributedText() {
        guard let text = text else { return }
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSMakeRange(0, attributedString.length)
        attributedString.addAttributes(attributes, range: range)
        attributedText = attributedString
    }
}
