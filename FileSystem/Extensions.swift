//
//  Extensions.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

// MARK: - Dictionary

extension Dictionary where Key == Int {
    
    var uniqueKey: Int {
        var numericOpenedFileDescriptor: Int
        repeat {
            numericOpenedFileDescriptor = Int.random(in: 0..<Int(UInt16.max))
        } while keys.contains(numericOpenedFileDescriptor)
        return numericOpenedFileDescriptor
    }
}

// MARK: - Collection

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(
        safe index: Index
    ) -> Element? {
        indices.contains(index)
            ? self[index]
            : nil
    }
}

// MARK: - Array

extension Array {
    
    mutating func removeLast(
        _ k: Int
    ) -> [Element] {
        (0..<k).map { _ in removeLast() }
    }
    
    func chunked(
        into size: Int,
        from position: Int = 0,
        to element: Int? = nil
    ) -> [[Element]] {
        stride(
            from: position,
            to: element == nil ? count : element!,
            by: size
        ).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Int

extension Int {
    
    var toString: String {
        String(self)
    }
}

// MARK: - CGFloat

extension CGFloat {
    
    static func roundUp(
        _ number: Self
    ) -> Int {
        Int(ceil(number))
    }
}

// MARK: - String

extension String {
    
    struct TrimOptionSet: OptionSet {
        
        let rawValue: Int
        
        static let whitespaces = TrimOptionSet(rawValue: 1 << 0)
        static let controlCharacters = TrimOptionSet(rawValue: 1 << 1)
    }
    
    func trim(
        _ optionSet: TrimOptionSet
    ) -> String {
        
        var characterSet = CharacterSet()
        
        if optionSet.contains(.whitespaces) {
            characterSet = characterSet.union(.whitespaces)
        }
        if optionSet.contains(.controlCharacters) {
            characterSet = characterSet.union(.controlCharacters)
        }
        return trimmingCharacters(in: characterSet)
    }
    
    func padding(
        _ length: Int
    ) -> String {
        padding(
            toLength: length,
            withPad: " ",
            startingAt: 0
        )
    }
    
    var withoutLastPathComponent: (pathComponent: String, path: String) {
        let isFromRoot = starts(with: "/") ? "/" : ""
        var path = split(separator: "/").map { String($0) }
        let pathComponent = String(path.removeLast())
        let newPath = isFromRoot + path.joined(separator: "/")
        return (
            pathComponent: pathComponent,
            path: newPath.isEmpty ? "." : newPath
        )
    }
}
