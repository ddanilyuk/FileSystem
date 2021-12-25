//
//  LinkCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 25.12.2021.
//

import Foundation

struct LinkCommand: Command {
    
    struct InputType {
        var name: String
        var linkName: String
    }
    
    static func execute(_ inputs: InputType) {
        print("\n~$ link \(inputs.name) \(inputs.linkName)")
        FileSystem.link(
            to: inputs.name,
            linkName: inputs.linkName
        )
        print("File with name \"\(inputs.name)\" now have link \"\(inputs.linkName)\"")
    }
}
