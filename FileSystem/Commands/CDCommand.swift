//
//  CDCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 27.12.2021.
//

import Foundation

struct CDCommand: Command {
    
    static func execute(_ path: String) {
        print("\n\(Path.currentPath)$ cd \(path)")
        FileSystem.cd(path)
    }
}
