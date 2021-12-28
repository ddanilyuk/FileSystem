//
//  UnlinkCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 25.12.2021.
//

import Foundation

struct UnlinkCommand: Command {
        
    static func execute(_ path: String) {
        print("\n\(Path.currentPath)$ unlink \(path)")
        FileSystem.unlink(path: path)
        print("File with name \"\(path)\" unlinked")
    }
}
