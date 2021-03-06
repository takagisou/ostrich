//
//  Util.swift
//  ostrich
//
//  Created by Ryan Conway on 2/21/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


// Utility
/// Make a `UInt16` out of two individual bytes
public func make16(high: UInt8, low: UInt8) -> UInt16 {
    var result = UInt16(high)
    result <<= 8
    result |= UInt16(low)
    
    return result
}

func endianSwap(_ val: UInt16) -> UInt16 {
    let (high, low) = getBytes(val)
    return make16(high: low, low: high)
}

/// Return (MSB, LSB) of a host-endian 16-bit number
func getBytes(_ val: UInt16) -> (UInt8, UInt8) {
    return (getHigh(val), getLow(val))
}

/// Get the least significant byte of a host-endian 16-bit number
func getLow(_ val: UInt16) -> UInt8 {
    return UInt8(truncatingBitPattern: val)
}

/// Get the most significant byte of a host-endian 16-bit number
func getHigh(_ val: UInt16) -> UInt8 {
    return UInt8(val >> 8)
}

/// Determine if a number is "negative" (if its MSB is high)
func numberIsNegative(_ num: UInt16) -> Bool {
    return bitIsHigh(num, bit: 15)
}

func numberIsNegative(_ num: UInt8) -> Bool {
    return bitIsHigh(num, bit: 7)
}

/// For symmetry or something
func numberIsZero(_ num: UInt16) -> Bool {
    return num == 0
}

func numberIsZero(_ num: UInt8) -> Bool {
    return num == 0
}

/// Test a zero-based bit of a 16-bit number
public func bitIsHigh(_ num: UInt16, bit: UInt16) -> Bool {
    let mask = 0x0001 << bit
    if num & mask != 0 {
        return true
    }
    
    return false
}

/// Test a zero-based bit of an 8-bit number
public func bitIsHigh(_ num: UInt8, bit: UInt8) -> Bool {
    let mask = UInt8(0x01 << bit)
    if num & mask != 0 {
        return true
    }
    
    return false
}

/// Set a zero-based bit of an 8-bit number
func setBit(_ num: UInt8, bit: UInt8) -> UInt8 {
    let mask = UInt8(0x01 << bit)
    
    return num | mask
}

/// Clear a zero-based bit of an 8-bit number
func clearBit(_ num: UInt8, bit: UInt8) -> UInt8 {
    let mask = ~(UInt8(0x01 << bit))
    
    return num & mask
}

/// Perform a right rotate
func rotateRight(_ num: UInt8) -> UInt8 {
    // Shift the number
    let shifted = logicalShiftRight(num)
    
    // Loop the number's least-significant bit back to the most-significant bit
    let newValue: UInt8
    if bitIsHigh(num, bit: 0) {
        newValue = setBit(shifted, bit: 7)
    } else {
        newValue = clearBit(shifted, bit: 7)
    }
    
    return newValue
}

/// Perform a left rotate in a way that doesn't depend on Swift's sign-specific shifting behavior
func rotateLeft(_ num: UInt8) -> UInt8 {
    // Shift the number
    let shifted = num << 1
    
    // Loop the number's most-significant bit back to the most-significant bit
    let newValue: UInt8
    if bitIsHigh(num, bit: 7) {
        newValue = setBit(shifted, bit: 0)
    } else {
        newValue = clearBit(shifted, bit: 0)
    }
    
    return newValue
}

/// Perform a left shift
func shiftLeft(_ num: UInt8) -> UInt8 {
    return num << 1
}

/// Perform a logical right shift (MSB becomes zero)
func logicalShiftRight(_ num: UInt8) -> UInt8 {
    return num >> 1
}

/// Perform an arithmetic right shift (MSB maintained)
func arithmeticShiftRight(_ num: UInt8) -> UInt8 {
    let asSigned = Int8(bitPattern: num)
    let shifted = asSigned >> 1
    
    return UInt8(bitPattern: shifted)
}

// ADD STUFF
func addOverflowOccurred(_ op1: UInt8, _ op2: UInt8, result: UInt8) -> Bool {
    if numberIsNegative(op1) && numberIsNegative(op2) && !numberIsNegative(result) {
        return true
    }
    if !numberIsNegative(op1) && !numberIsNegative(op2) && numberIsNegative(result) {
        return true
    }
    
    return false
}

// This behavior is consistent with the BSNES core
func addHalfCarryProne(_ op1: UInt8, _ op2: UInt8) -> Bool {
    return (op1 & 0x0F) + (op2 & 0x0F) >= 0x10
}

/// 8080 half-carry for 16-bit numbers is on bit 11, not bit 7
func addHalfCarryProne(_ op1: UInt16, _ op2: UInt16) -> Bool {
    return (op1 & 0x0FFF) + (op2 & 0x0FFF) >= 0x0FFF
}

func addHalfCarryProne(_ op1: UInt16, _ op2: Int8) -> Bool {
    return (op1 & 0x000F) + (UInt16(UInt8(bitPattern: op2)) & 0x000F) >= 0x000F
}

func addHalfCarryProne(_ op1: UInt8, _ op2: UInt8, _ op3: UInt8) -> Bool {
    return (op1 & 0x0F) + (op2 & 0x0F) + (op3 & 0x0F) >= 0x10
}

func addCarryProne(_ op1: UInt8, _ op2: UInt8) -> Bool {
    let overflowedResult: UInt16 = UInt16(op1) + UInt16(op2)
    
    return overflowedResult > 0xFF
}

func addCarryProne(_ op1: UInt16, _ op2: UInt16) -> Bool {
    let overflowedResult: UInt32 = UInt32(op1) + UInt32(op2)
    
    return overflowedResult > 0xFFFF
}

func addCarryProne(_ op1: UInt16, _ op2: Int8) -> Bool {
    return addCarryProne(UInt8(truncatingBitPattern: op1), UInt8(bitPattern: op2))
}

func addCarryProne(_ op1: UInt8, _ op2: UInt8, _ op3: UInt8) -> Bool {
    let overflowedResult: UInt16 = UInt16(op1) + UInt16(op2) + UInt16(op3)
    
    return overflowedResult > 0xFF
}

// SUB STUFF
func subOverflowOccurred(_ op1: UInt8, op2: UInt8, result: UInt8) -> Bool {
    // If you subtract a positive number from a negative one, the result should always be negative
    if numberIsNegative(op1) && !numberIsNegative(op2) && !numberIsNegative(result) {
        return true
    }
    // If you subtract a negative number from a positive one, the result should always be positive
    if !numberIsNegative(op1) && numberIsNegative(op2) && numberIsNegative(result) {
        return true
    }
    
    return false
}

func subHalfBorrowProne(_ op1: UInt8, _ op2: UInt8) -> Bool {
    return sub(op1 & 0x0F, op2 & 0x0F) > 0x0F
}

func subHalfBorrowProne(_ op1: UInt8, _ op2: UInt8, _ op3: UInt8) -> Bool {
    return sub(sub(op1 & 0x0F, op2 & 0x0F), op3 & 0x0F) > 0x0F
}

func subBorrowProne(_ op1: UInt8, _ op2: UInt8) -> Bool {
    return sub(UInt16(op1), UInt16(op2)) > 0xFF
}

func subBorrowProne(_ op1: UInt8, _ op2: UInt8, _ op3: UInt8) -> Bool {
    return sub(sub(UInt16(op1), UInt16(op2)), UInt16(op3)) > 0xFF
}


/// Odd number of high bits: false; even number of high bits: true
func parity(_ num: UInt8) -> Bool {
    var highBits = 0
    
    for i in UInt8(0) ... UInt8(7) {
        if bitIsHigh(num, bit: i) {
            highBits = highBits + 1
        }
    }
    
    if highBits % 2 == 0 {
        return true
    }
    return false
}


protocol HexStringConvertible {
    /// Representation of this number as 0x%0#X
    var hexString: String { get }
}

protocol BinaryStringConvertible {
    var binaryString: String { get }
}

extension UInt8: HexStringConvertible {
    /// Representation of this number as 0x%02X
    var hexString: String { return String(format: "0x%02X", self) }
}

extension UInt16: HexStringConvertible {
    /// Representation of this number as 0x%04X
    var hexString: String { return String(format: "0x%04X", self) }
}

extension UInt8: BinaryStringConvertible {
    /// Representation of this number as 0x%02X
    var binaryString: String { return String(self, radix: 2) }
}

extension UInt16: BinaryStringConvertible {
    /// Representation of this number as 0x%04X
    var binaryString: String { return String(self, radix: 2) }
}
