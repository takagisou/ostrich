//
//  Peripherals.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/4/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


public typealias Address = UInt16


public protocol BusListener {
    var firstAddress: Address { get }
    var lastAddress: Address { get }
    var addressRange: Range<Address> { get }
}
public protocol HandlesReads {
    func read(addr: Address) -> UInt8
}
public protocol HandlesWrites {
    func write(val: UInt8, to addr: Address)
}

public protocol Memory: BusListener, HandlesReads {}