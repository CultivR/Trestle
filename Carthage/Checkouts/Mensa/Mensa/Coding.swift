//
//  Coding.swift
//  Mensa
//
//  Created by Jordan Kay on 2/13/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

private var swizzledClasses = Set<String>()

public extension NSCoding where Self: NSObject {
    func decodeProperties(from coder: NSCoder, manuallyDecode: () -> Void = {}) {
#if !TARGET_INTERFACE_BUILDER
        guard coder is NSKeyedUnarchiver else { return }
        properties.forEach { key, _ in
            if let value = coder.decodeObject(forKey: key), !(value is NSNull) {
                setValue(value, forKey: key)
            }
        }
        manuallyDecode()
#endif
    }
    
    func encodeProperties(with coder: NSCoder, manuallyEncode: () -> Void = {}) {
#if !TARGET_INTERFACE_BUILDER
        properties.forEach { key, value in
            if self.value(forKey: key) != nil {
                coder.encode(value, forKey: key)
            }
        }
        manuallyEncode()
#endif
    }
}

extension UIView {
    static func setupCoding(for name: String) {
        if swizzledClasses.count == 0 {
            let originalDecode = class_getInstanceMethod(UIView.self, #selector(UIView.init(coder:)))
            let swizzledDecode = class_getInstanceMethod(UIView.self, #selector(UIView.initForDuplicationWithCoder(_:)))
            method_exchangeImplementations(originalDecode, swizzledDecode)
            
            let originalEncode = class_getInstanceMethod(UIView.self, #selector(UIView.encode(with:)))
            let swizzledEncode = class_getInstanceMethod(UIView.self, #selector(UIView.encodeForDuplicationWithCoder(_:)))
            method_exchangeImplementations(originalEncode, swizzledEncode)
        }
        swizzledClasses.insert(name)
    }
    
    @objc func initForDuplicationWithCoder(_ coder: NSCoder) -> UIView {
        let view = initForDuplicationWithCoder(coder)
        guard swizzledClasses.contains(name) else { return view }
        decodeProperties(from: coder)
        return view
    }
    
    @objc func encodeForDuplicationWithCoder(_ coder: NSCoder) {
        encodeForDuplicationWithCoder(coder)
        guard swizzledClasses.contains(name) else { return }
        encodeProperties(with: coder)
    }
    
    open override func value(forUndefinedKey key: String) -> Any? { return nil }
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {}
}

private extension NSCoding {
    var name: String {
        return String(describing: type(of: self))
    }
    
    var properties: [(String, Any)] {
        var mirror: Mirror? = Mirror(reflecting: self)
        var properties: [(String, Any)] = []
        while mirror != nil {
            properties += mirror!.children
                .filter { $0.label != nil && !$0.label!.contains(".") }
                .map { ($0.label!, $0.value) }
            mirror = mirror?.superclassMirror
        }
        return properties
    }
}
