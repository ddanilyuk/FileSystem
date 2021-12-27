//
//  SymlinkCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 27.12.2021.
//

import Foundation

struct SymlinkCommand: Command {
    
    struct InputType {
        var str: String
        var path: String
    }
    
    static func execute(_ input: InputType) {
        print("\n\(Path.currentPath)$ ln -s \(input.str) \(input.path)")
        FileSystem.simlink(str: input.str, path: input.path)
    }
}
