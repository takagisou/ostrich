//
//  SLA.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/21/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Arithmetic left shift into carry flag
struct SLA<T: Writeable & Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == T.WriteType, T.ReadType == UInt8
{
    let op: T
    
    let cycleCount = 0
    
    
    fileprivate func runCommon(_ cpu: Intel8080Like) -> (UInt8, UInt8) {
        let oldValue = op.read()
        let newValue = shiftLeft(oldValue)
        
        op.write(newValue)
        
        return (oldValue, newValue)
    }
    
    func runOn(_ cpu: Z80) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    func runOn(_ cpu: LR35902) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, oldValue: UInt8, newValue: UInt8) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is reset.
        // N is reset.
        // C is data from bit 7.
        
        cpu.ZF.write(newValue == 0x00)
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(bitIsHigh(oldValue, bit: 7))
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if parity is even; otherwise, it is reset.
        
        cpu.SF.write(numberIsNegative(newValue))
        cpu.PVF.write(parity(newValue))
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
}
