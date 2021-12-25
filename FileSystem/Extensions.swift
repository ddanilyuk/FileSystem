//
//  Extensions.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

extension Dictionary where Key == Int {
    
    var uniqueKey: Int {
        var numericOpenedFileDescriptor: Int
        repeat {
            numericOpenedFileDescriptor = Int.random(in: 0..<Int(UInt16.max))
        } while keys.contains(numericOpenedFileDescriptor)
        return numericOpenedFileDescriptor
    }
}

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    
    mutating func removeLast(_ numberOfElementsToRemove: Int) -> [Element] {
        (0..<numberOfElementsToRemove).map { _ in removeLast() }
    }
    
    func chunked(
        into size: Int,
        from position: Int = 0,
        to element: Int? = nil
    ) -> [[Element]] {
        let element = element == nil ? count : element!
        return stride(from: position, to: element, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
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

extension String {
    
    struct TrimOptionSet: OptionSet {
        
        let rawValue: Int
        
        static let whitespaces = TrimOptionSet(rawValue: 1 << 0)
        static let controlCharacters = TrimOptionSet(rawValue: 1 << 1)
    }
    
    func trim(_ optionSet: TrimOptionSet) -> String {
        
        var characterSet = CharacterSet()
        
        if optionSet.contains(.whitespaces) {
            characterSet = characterSet.union(.whitespaces)
        }
        if optionSet.contains(.controlCharacters) {
            characterSet = characterSet.union(.controlCharacters)
        }
        return trimmingCharacters(in: characterSet)
    }
}
