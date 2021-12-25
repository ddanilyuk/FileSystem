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
        var nameFileToLink: String
    }
    
    static func execute(_ inputs: InputType) {
        print("\n~$ link \(inputs.name) \(inputs.nameFileToLink)")
        FileSystemDriver.shared.link(
            to: inputs.name,
            nameToLink: inputs.nameFileToLink
        )
        print("File with name \(inputs.name) now have link \(inputs.nameFileToLink)")
    }
}
