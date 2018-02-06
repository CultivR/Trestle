//
//  TextView.swift
//  Trestle
//
//  Created by Jordan Kay on 5/9/18.
//  Copyright © 2018 Cultivr. All rights reserved.
//

public extension UITextView {
    var html: String {
        get {
            return text
        }
        set {
            guard let font = font, let textColor = textColor else { return }
            let data = newValue.data(using: .utf8)!
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue]
            let string = try! NSMutableAttributedString(data: data, options: options, documentAttributes: nil)
            let range = NSRange(location: 0, length: (string.string as NSString).length)
            let sizeOffset = font.pointSize - .htmlFontSize
            
            string.addAttribute(.foregroundColor, value: textColor, range: range)
            string.enumerateAttribute(.font, in: range, options: .reverse) { attribute, attributeRange, _ in
                let styledFont = (attribute as! UIFont).styled(like: font, withSizeOffset: sizeOffset)
                string.addAttribute(.font, value: styledFont, range: attributeRange)
            }
            attributedText = string
        }
    }
}

private extension CGFloat {
    static let htmlFontSize: CGFloat = 12
}
