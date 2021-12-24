//
//  Extensions.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension String {
    
    func padding(_ length: Int) -> String {
        return padding(toLength: length, withPad: " ", startingAt: 0)
    }
}

extension Int {
    var toString: String {
        String(self)
    }
}

extension CGFloat {
    
    static func roundUp(_ number: Self) -> Int {
        return Int(ceil(number))
    }
}
