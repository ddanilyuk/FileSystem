//
//  MKDirCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 27.12.2021.
//

import Foundation

struct MKDirCommand: Command {
    
    static func execute(_ path: String) {
        print("\n\(Path.currentPath)$ mkdir \(path)")
        FileSystem.mkdir(path)
    }
}
