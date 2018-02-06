//
//  IconLabel.swift
//  Trestle
//
//  Created by Jordan Kay on 10/30/17.
//  Copyright © 2017 Cultivr. All rights reserved.
//

public final class IconLabel: UILabel {
    @IBInspectable private var icon: UIImage!
    @IBInspectable private var iconVerticalOffset: CGFloat = 0.0
    
    // MARK: UIView
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: NSCoding
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        decodeProperties(from: coder)
    }
}

public extension IconLabel {
    // MARK: UIView
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += .padding
        return size
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateAttributedText()
    }
    
    // MARK: UILabel
    override var text: String? {
        didSet {
            updateAttributedText()
        }
    }
    
    override func drawText(in rect: CGRect) {
        var rect = rect
        rect.origin.x += .padding
        super.drawText(in: rect)
    }
    
    // MARK: NSCoding
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        encodeProperties(with: coder)
    }
}

private extension IconLabel {
    func updateAttributedText() {
        let iconAttachment = Attachment()
        iconAttachment.verticalOffset = iconVerticalOffset
        iconAttachment.image = icon
        
        let iconString = NSAttributedString(attachment: iconAttachment)
        let string = NSMutableAttributedString(string: text ?? "")
        string.insert(iconString, at: 0)
        
        attributedText = string
    }
}

private class Attachment: NSTextAttachment {
    var verticalOffset: CGFloat = 0.0
    
    // MARK: NSTextAttachmentContainer
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        var bounds = super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        bounds.origin.x -= .padding
        bounds.origin.y += verticalOffset
        return bounds
    }
}

private extension CGFloat {
    static let padding: CGFloat = 4
}
