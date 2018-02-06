//
//  Font.swift
//  Trestle
//
//  Created by Jordan Kay on 5/9/18.
//  Copyright © 2018 Cultivr. All rights reserved.
//

public extension UIFont {
    func styled(like font: UIFont, withSizeOffset offset: CGFloat) -> UIFont {
        var attributes = fontDescriptor.fontAttributes
        let otherAttributes = font.fontDescriptor.fontAttributes
        let traits = fontDescriptor.symbolicTraits
        let size = attributes[.size] as! CGFloat + offset
        
        var descriptor = UIFontDescriptor(fontAttributes: otherAttributes)
        descriptor = descriptor.withSymbolicTraits(traits) ?? descriptor
        return UIFont(descriptor: descriptor, size: size)
    }
}

public protocol FontScalable {
    func scaleFontSize(by scale: CGFloat, minimum: CGFloat)
}

extension UILabel: FontScalable {
    public func scaleFontSize(by scale: CGFloat, minimum: CGFloat = 14) {
        let size = max(minimum, font.pointSize * scale)
        font = UIFont(descriptor: font.fontDescriptor, size: size)
    }
}

extension UITextView: FontScalable {
    public func scaleFontSize(by scale: CGFloat, minimum: CGFloat = 14) {
        guard let font = font else { return }
        let size = max(minimum, font.pointSize * scale)
        self.font = UIFont(descriptor: font.fontDescriptor, size: size)
    }
}
