//
//  ByteArray.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 19.12.2021.
//

import Foundation

typealias Byte = UInt8
typealias ByteArray = [Byte]

extension RandomAccessCollection where Element == Byte {
    
    var isClear: Bool {
        !contains { $0 != 0 }
    }
    
    var toInt: Int {
        guard
            count == Constants.intSize
        else {
            fatalError("Invalid number of bytes")
        }
            
        return reduce(0) { soFar, byte in
            return soFar << 8 | Int(byte)
        }
    }
    
    var toString: String {
        
        if let string = String(bytes: self, encoding: .utf8) {
            return string
        } else {
            fatalError("Cant represent string")
        }
    }
}


extension Int {
    
    var bytes: ByteArray {
        if self > UInt16.max {
            assertionFailure("Can't represent this value")
        }
        return [UInt8(self >> 8 & 0xff), UInt8(self & 0xff)]
    }
}


//let some = Array<Byte>
