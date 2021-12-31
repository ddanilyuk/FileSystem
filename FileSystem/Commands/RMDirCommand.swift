//
//  RMDirCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 28.12.2021.
//

import Foundation

struct RMDirCommand: Command {
    
    static func execute(_ path: String) {
        print("\n\(Path.currentPath)$ rmdir \(path)")
        FileSystem.rmdir(path)
    }
}
