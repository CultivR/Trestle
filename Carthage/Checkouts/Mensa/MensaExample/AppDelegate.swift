//
//  AppDelegate.swift
//  MensaExample
//
//  Created by Jordan Kay on 6/20/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

import Mensa

@UIApplicationMain
class AppDelegate: UIResponder {
    var window: UIWindow?
}

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        Registration.register(itemType: Number.self, viewType: NumberView.self, controllerType: NumberViewController.self)
        Registration.register(itemType: PrimeFlag.self, viewType: PrimeFlagView.self, controllerType: PrimeFlagViewController.self)
        return true
    }
}
