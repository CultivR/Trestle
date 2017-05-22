//
//  Example.swift
//  Mensa
//
//  Created by Jordan Kay on 6/22/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//


func sampleItems(count: Int) -> [NumberOrPrimeFlag] {
    var items: [NumberOrPrimeFlag] = []
    for index in (1...count) {
        var number = Number(index)
        items.append(number)
        if number.prime {
            items.append(PrimeFlag(number: number))
        }
    }
    return items
}
