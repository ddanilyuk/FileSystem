//
//  MKDirCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 27.12.2021.
//

import Foundation

struct MKDirCommand: Command {
    
    static func execute(_ name: String) {
        print("\n\(Path.currentPath)$ mkdir \(name)")
        FileSystem.mkdir(name)
    }
}
