//
//  DataSource.swift
//  Mensa
//
//  Created by Jordan Kay on 5/8/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

/// Protocol to adopt in order to provide sections of data.
public protocol DataSource {
    associatedtype Item
    
    var sections: [Section<Item>] { get }
}
