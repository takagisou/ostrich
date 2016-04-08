//
//  Registers.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


protocol RegisterType: Readable, Writeable {}

/// An 8-bit register: some CPU-built-in memory cell that holds an 8-bit value
class Register8: RegisterType, OperandType {
    var val: UInt8
    
    init(val: UInt8) {
        self.val = val
    }
    
    func read() -> UInt8 {
        return val
    }
    
    func write(val: UInt8) {
        self.val = val
    }
    
    var operandType: OperandKind {
        return OperandKind.Register8Like
    }
}

/// A flag: a computed property that is a single bit of an 8-bit register, readable and writeable as a Bool
class Flag: Readable, Writeable {
    let reg: Register8
    let bitNumber: UInt8
    
    init(reg: Register8, bitNumber: UInt8) {
        self.reg = reg
        self.bitNumber = bitNumber
    }
    
    func read() -> Bool {
        let regVal = reg.read()
        let mask = UInt8(0x01 << bitNumber)
        
        if regVal & mask != 0 {
            return true
        }
        
        return false
    }
    
    /// not thread safe
    func write(val: Bool) {
        var newVal = reg.read()
        if val {
            let mask = UInt8(0x01 << bitNumber)
            newVal |= mask
            reg.write(newVal)
        }
    }
}


protocol CanActAsPointer: Readable, Writeable {
    func dereferenceOn(bus: DataBus) -> UInt8
    func storeInLocation(bus: DataBus, val: UInt8)
}

/// A 16-bit register: some CPU-built-in memory cell that holds a 16-bit value
class Register16: RegisterType, OperandType, CanActAsPointer {
    var val: UInt16
    
    init(val: UInt16) {
        self.val = val
    }
    
    func read() -> UInt16 {
        return val
    }
    
    func write(val: UInt16) {
        self.val = val
    }
    
    var operandType: OperandKind {
        return OperandKind.Register16Like
    }
    
    private func asPointerOn(bus: DataBus) -> Pointer<Register16> {
        return Pointer(source: self, bus: bus)
    }
    
    func dereferenceOn(bus: DataBus) -> UInt8 {
        return self.asPointerOn(bus).read()
    }
    
    func storeInLocation(bus: DataBus, val: UInt8) {
        self.asPointerOn(bus).write(val)
    }
}

/// A virtual 16-bit register, computed from two 8-bit registers
class Register16Computed: RegisterType, OperandType, CanActAsPointer {
    let high: Register8
    let low: Register8
    
    init(high: Register8, low: Register8) {
        self.high = high
        self.low = low
    }
    
    func read() -> UInt16 {
        let highVal = self.high.read()
        let lowVal = self.low.read()
        
        return make16(high: highVal, low: lowVal)
    }
    
    /// Write assuming host endianness
    func write(val: UInt16) {
        self.high.write(getHigh(val))
        self.low.write(getLow(val))
    }
    
    var operandType: OperandKind {
        return OperandKind.Register16ComputedLike
    }
    
    func asPointerOn(bus: DataBus) -> Pointer<Register16Computed> {
        return Pointer(source: self, bus: bus)
    }
    
    func dereferenceOn(bus: DataBus) -> UInt8 {
        return self.asPointerOn(bus).read()
    }
    
    func storeInLocation(bus: DataBus, val: UInt8) {
        self.asPointerOn(bus).write(val)
    }
}

/// A 16-bit register whose value is interpreted as an address to an 8-bit value to read from or write to.
class Pointer<T: Readable where T.ReadType == Address>: Readable, Writeable, OperandType {
    let source: T
    let bus: DataBus
    
    init(source: T, bus: DataBus) {
        self.source = source
        self.bus = bus
    }
    
    func read() -> UInt8 {
        return bus.read(source.read())
    }
    
    func write(val: UInt8) {
        bus.write(val, to: source.read())
    }
    
    var operandType: OperandKind {
        return OperandKind.Register16Indirect8Like
    }
}

/// An optional 8-bit operand whose value is added to a fixed address to point to an 8-bit value to read from or
/// write to.
class PseudoPointer8<T: Readable where T.ReadType == UInt8>: Readable, Writeable, OperandType {
    let base: Address
    let offset: T
    let bus: DataBus
    
    init(base: UInt16, offset: T, bus: DataBus) {
        self.base = base
        self.offset = offset
        self.bus = bus
    }
    
    var offsetInt: Int8 {
        return Int8(bitPattern: offset.read())
    }
    var targetAddress: Address {
        return Address(Int(base) + offsetInt)
    }
    
    func read() -> UInt8 {
        return bus.read(targetAddress)
    }
    
    func write(val: UInt8) {
        bus.write(val, to: targetAddress)
    }
    
    var operandType: OperandKind {
        return OperandKind.Register16Indirect8Like
    }
}

class PseudoPointer16<T: Readable where T.ReadType == UInt8>: Readable, Writeable, OperandType {
    let base: Address
    let offset: T
    let bus: DataBus
    
    init(base: UInt16, offset: T, bus: DataBus) {
        self.base = base
        self.offset = offset
        self.bus = bus
    }
    
    var offsetInt: Int8 {
        return Int8(bitPattern: offset.read())
    }
    var targetAddress: Address {
        return Address(Int(base) + offsetInt)
    }
    
    func read() -> UInt16 {
        return bus.read16(targetAddress)
    }
    
    func write(val: UInt16) {
        bus.write16(val, to: targetAddress)
    }
    
    var operandType: OperandKind {
        return OperandKind.Register16Indirect8Like
    }
}