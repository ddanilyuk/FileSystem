//
//  CreateCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct CreateCommand: Command {
        
    static func execute(_ path: String) {
        print("\n\(Path.currentPath)$ touch \(path)")
        FileSystem.createFile(with: path)
        print("File successfully created")
    }
}
