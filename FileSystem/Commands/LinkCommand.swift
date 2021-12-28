//
//  LinkCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 25.12.2021.
//

import Foundation

struct LinkCommand: Command {
    
    struct InputType {
        var path: String
        var linkPath: String
    }
    
    static func execute(_ inputs: InputType) {
        print("\n\(Path.currentPath)$ link \(inputs.path) \(inputs.linkPath)")
        FileSystem.link(
            to: inputs.path,
            linkPath: inputs.linkPath
        )
        print("File with name \"\(inputs.path)\" now have link \"\(inputs.linkPath)\"")
    }
}
