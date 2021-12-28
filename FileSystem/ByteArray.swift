//
//  ByteArray.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 19.12.2021.
//

import Foundation

typealias Byte = UInt8
typealias ByteArray = [Byte]

// MARK: - MutableCollection

extension MutableCollection where Element == Byte, Index == Int {
    
    var isClear: Bool {
        !contains { $0 != 0 }
    }
    
    var toInt: Int {
        guard
            count == Constants.Common.intSize
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
    
    var toFileName: String {
        toString.trim([.controlCharacters, .whitespaces])
    }
    
    var fileNameChunk: ByteArray {
        ByteArray(self[0..<Constants.Common.fileNameSize])
    }
    
    var descriptorIndexChunk: ByteArray {
        ByteArray(self[Constants.Common.fileNameSize...])
    }
    
    var dataChunk: ByteArray {
        ByteArray(self[..<Constants.Block.dataSize])
    }
    
    var linkChunk: ByteArray {
        ByteArray(self[Constants.Block.dataSize...])
    }
}

// MARK: - Convenience empty init

extension Array where Element == Byte {
    
    init(size: Int) {
        self = ByteArray(repeating: 0, count: size)
    }
}

// MARK: - Int

extension Int {
    
    var toBytes: ByteArray {
        [Byte(self >> 8 & 0xff), Byte(self & 0xff)]
    }
}

// MARK: - Srting

extension String {
    
    var toBytes: ByteArray {
        ByteArray(utf8)
    }
}
