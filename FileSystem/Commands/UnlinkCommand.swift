//
//  UnlinkCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 25.12.2021.
//

import Foundation

struct UnlinkCommand: Command {
        
    static func execute(_ name: String) {
        print("\n\(Path.currentPath)$ unlink \(name)")
        FileSystem.unlink(name: name)
        print("File with name \"\(name)\" unlinked")
    }
}
