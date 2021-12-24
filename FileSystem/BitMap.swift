//
//  BitMap.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 19.12.2021.
//

import Foundation

public struct BitMap {
    
    // MARK: - Properties
    
    private let size: Int
    private var bits: [Bool] = []
    
    // MARK: - Lifecycle
    
    init(size: Int) {
        self.size = size
        self.bits = Array(repeating: false, count: size)
    }
    
    // MARK: - Public methods
    
    func test(position: Int) -> Bool {
        return bits[position]
    }
    
    mutating func set(position: Int) {
        bits[position] = true
    }
    
    mutating func reset(position: Int) {
        bits[position] = false
    }
}
