//
//  OpenCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct OpenCommand: Command {
        
    static func execute(_ path: String) -> Int {
        print("\n\(Path.currentPath)$ open")
        let result = FileSystem.openFile(with: path)
        print("File opened with id: \(result)")
        return result
    }
}
