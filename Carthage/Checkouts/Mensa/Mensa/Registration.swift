//
//  Registration.swift
//  Mensa
//
//  Created by Jordan Kay on 5/5/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

public enum Registration {
    private(set) static var viewTypes: [String: UIView.Type] = [:]
    private(set) static var viewControllerTypes: [String: () -> ItemDisplayingViewController] = [:]
    
    // Globally register a view controller type to use to display an item type.
    public static func register<Item, View: UIView, ViewController: UIViewController>(itemType: Item.Type, conformingTypes: [Any.Type] = [], viewType: View.Type, controllerType: ViewController.Type) where Item == ViewController.Item, ViewController: ItemDisplaying {
        let types = [itemType] + conformingTypes
        for type in types {
            let key = String(describing: type)
            viewTypes[key] = viewType
            viewControllerTypes[key] = {
                let viewController = controllerType.init()
                return ItemDisplayingViewController(viewController)
            }
        }
    }
}
