//
//  OpenCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct OpenCommand: Command {
        
    static func execute(_ name: String) -> Int {
        print("\n~$ open")
        let result = FileSystem.openFile(with: name)
        print("File opened with id: \(result)")
        return result
    }
}
