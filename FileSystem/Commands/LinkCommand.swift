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
        var linkName: String
    }
    
    static func execute(_ inputs: InputType) {
        print("\n\(Path.currentPath)$ link \(inputs.path) \(inputs.linkName)")
        FileSystem.link(
            to: inputs.path,
            linkName: inputs.linkName
        )
        print("File with name \"\(inputs.path)\" now have link \"\(inputs.linkName)\"")
    }
}
