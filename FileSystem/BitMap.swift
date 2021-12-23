//
//  BitMap.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 19.12.2021.
//

import Foundation


public struct BitMap {
    
    private let size: Int
    private var bits: [Bool] = []
    
    init(size: Int) {
        self.size = size
        self.bits = Array(repeating: false, count: size)
    }
    
    func test(position: Int) -> Bool {
        return bits[position]
    }
    
    mutating func set(position: Int) {
        bits[position] = true
    }
    
    mutating func reset(position: Int) {
        bits[position] = false
    }
    
//    func enumerated() -> (index: Int, bit: Bool) {
//        return bits.enumerated()
//    }
}
